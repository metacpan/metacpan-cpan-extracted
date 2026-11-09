use strict;
use warnings;
use Test::More;

# OFFLINE regression for karr k101: the statement trace of the transport goes
# the way the sync storage's goes.
#
# WHY: bind values are credentials, tokens and personal data. The sync storage
# traces through its debug object, onto its debugfh, through the
# redact_bind_value hook; the transport wrote "$sql: 'bind', ..." with warn to
# STDERR, past all three, so DBIO_TRACE=1=/path still filled the process log.
#
# Claims, for the pooled path and the pinned one (a transaction):
#   1. the owning storage's debug object receives the statement
#      (query_start and query_end), and its debugfh gets the text, not STDERR;
#   2. below DBIO_TRACE=2 no bind value is traced; at 2 they are;
#   3. a traced value is cut at 32 characters, with '...' marking the cut
#      (the rule of core's _debug_query, ADR 0025, core k402);
#   4. redact_bind_value is asked for every value, and what it returns is shown;
#   5. an undefined value is NULL; nothing is traced while debug is off;
#   6. the transport carries no trace of its own: a ResultSet statement brings
#      its bind attributes (core k402), so a column with encode_column shows
#      '***' and a custom hook sees the column name; a raw statement gives
#      the hook undef for the name; a select with a bind attribute (core k404)
#      runs traced at level 2 and returns its rows.
#
# THE ONE SUBSTITUTION is EV::Pg, a fake that answers every statement.

BEGIN {
  package EV::Pg;
  use Scalar::Util ();

  our @DATA;    # every chunk put_copy_data was given

  sub new {
    my ($class, %args) = @_;
    my $self = bless { on_connect => $args{on_connect}, conn => 0, queue => [] }, $class;
    Scalar::Util::weaken(my $weak = $self);
    my $t;
    $t = EV::timer(0.001, 0, sub {
      undef $t;
      return unless $weak;
      $weak->{conn} = 1;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  sub is_connected  { $_[0]{conn} ? 1 : 0 }
  sub pending_count { scalar @{ $_[0]{queue} } }
  sub socket        { -1 }
  sub error_message { undef }
  sub finish        { $_[0]{conn} = 0; return }

  our @ANSWER = ([ 1 ]);
  our @SENT;    # [ $sql, $bind ] of every query_params

  sub result_meta { { cmd_status => 'COMMIT' } }

  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    push @SENT, [ $sql, [ @$bind ] ];
    my $t;
    $t = EV::timer(0.001, 0, sub { undef $t; $cb->([ map { [@$_] } @ANSWER ]) });
    return;
  }

  sub query {
    my ($self, $sql, $cb) = @_;
    $self->{cb} = $cb;
    my $t;
    $t = EV::timer(0.001, 0, sub { undef $t; $cb->('COPY_IN') });
    return;
  }

  sub put_copy_data { push @DATA, $_[1]; return 1 }

  sub put_copy_end {
    my ($self) = @_;
    my $cb = $self->{cb};
    my $t;
    $t = EV::timer(0.001, 0, sub { undef $t; $cb->(scalar @DATA) });
    return 1;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBIO::Schema;
use DBIO::Storage::Statistics;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::EV::Storage;

{
  package DBIO::Test::K101Trace;
  $INC{'DBIO/Test/K101Trace.pm'} = 1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

{
  package K113::Schema::Result::User;
  $INC{'K113/Schema/Result/User.pm'} = 1;
  use base 'DBIO::Core';
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    name  => { data_type => 'varchar', size => 64, is_nullable => 1 },
    token => { data_type => 'varchar', size => 64, is_nullable => 1, encode_column => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package K113::Schema;
  $INC{'K113/Schema.pm'} = 1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(User => 'K113::Schema::Result::User');
}

{
  package K101::Debug;
  use base 'DBIO::Storage::Statistics';
  our (@START, @END);
  sub query_start { my $s = shift; push @START, [@_]; $s->SUPER::query_start(@_) }
  sub query_end   { my $s = shift; push @END,   [@_]; $s->SUPER::query_end(@_) }
}

alarm 60;

my @stderr;
local $SIG{__WARN__} = sub { push @stderr, @_ };

sub traced {
  my ($level, $run, $class) = @_;
  local $ENV{DBIO_TRACE} = $level;
  my $schema  = ($class // 'DBIO::Test::K101Trace')->connect('dbi:Pg:dbname=x', 'u', 'p', { async => 'ev', pool_size => 1 });
  my $owner   = $schema->storage;
  my $buffer  = '';
  open my $fh, '>', \$buffer or die;
  my $debug = K101::Debug->new;
  $debug->debugfh($fh);
  $owner->debugobj($debug);
  @K101::Debug::START = @K101::Debug::END = ();
  @stderr = ();
  my $async = $owner->async;
  my $f = $run->($async, $schema);
  EV::now_update();
  my $dog = EV::timer(5, 0, sub { $f->fail("watchdog\n") unless $f->is_ready });
  $dog->keepalive(0);
  $f->get;
  $async->disconnect;
  return $buffer;
}

my $long = 'x' x 40;
my $sql  = 'INSERT INTO users ( name, token ) VALUES ( ?, ? )';
my @bind = ('bob', $long, undef);
my %path = (
  pooled => sub { $_[0]->_query_async($sql, [@bind]) },
);
$path{pinned} = sub {
  my ($async) = @_;
  $async->pool->acquire->then(sub {
    my $pg = shift;
    $async->_query_async_pinned($pg, $sql, [@bind]);
  });
};

for my $path (sort keys %path) {
  my $out = traced(1, $path{$path});
  is scalar(@K101::Debug::START), 1, "$path: the debug object is told of the statement";
  is scalar(@K101::Debug::END), 1, "$path: ... and of its end";
  like $out, qr/^INSERT INTO users \( name, token \) VALUES \( \$1, \$2 \)/m, "$path: the text is on the debugfh";
  unlike $out, qr/bob|xxxx/, "$path: DBIO_TRACE=1: no bind value";
  is_deeply \@stderr, [], "$path: nothing went to STDERR";

  $out = traced(2, $path{$path});
  like $out, qr/'bob', '\Q@{[ 'x' x 32 ]}\E\.\.\.', NULL\n/, "$path: DBIO_TRACE=2: binds, cut at 32 with '...', NULL for undef";
  unlike $out, qr/x{33}/, "$path: ... never more than 32 characters of a value";
  is_deeply \@stderr, [], "$path: ... and STDERR stays empty";

  {
    no warnings 'redefine';
    local *DBIO::Storage::DBI::redact_bind_value = sub {
      sub { my ($col, $val) = @_; $val eq 'bob' ? '***' : $val };
    };
    $out = traced(2, $path{$path});
    like $out, qr/'\*\*\*', 'x+(?:\.\.\.)?'/, "$path: the redactor decides what is shown";
    unlike $out, qr/bob/, "$path: ... and the value it hid is not in the trace";
  }

  $out = traced(0, $path{$path});
  is $out, '', "$path: debug off: nothing traced";
}

# --- 6. bind attributes: the trace is core's, the attributes come from the ResultSet ---

my $rs_create = sub {
  my ($async, $schema) = @_;
  $schema->resultset('User')->create_async({ name => 'bob', token => 'sekrit' });
};

{
  my $out = traced(2, $rs_create, 'K113::Schema');
  like $out, qr/INSERT INTO "users"/, 'resultset create: statement traced';
  like $out, qr/'bob'/, 'resultset create: plain column shown at level 2';
  like $out, qr/'\*\*\*'/, 'encode_column: the bind of the column is masked with ***';
  unlike $out, qr/sekrit/, 'encode_column: the value is not in the trace';

  my @seen;
  {
    no warnings 'redefine';
    local *DBIO::Storage::DBI::redact_bind_value = sub {
      sub { my ($col, $val) = @_; push @seen, [ $col, $val ]; $val };
    };
    traced(2, $rs_create, 'K113::Schema');
  }
  ok scalar(grep { defined $_->[0] && $_->[0] eq 'name' && $_->[1] eq 'bob' } @seen),
    'a custom redact_bind_value is told the column name';

  $out = traced(1, $rs_create, 'K113::Schema');
  like $out, qr/INSERT INTO "users"/, 'level 1: statement traced';
  unlike $out, qr/bob|sekrit|\*\*\*/, 'level 1: no bind value, not even a masked one';
}

{
  my @seen;
  {
    no warnings 'redefine';
    local *DBIO::Storage::DBI::redact_bind_value = sub {
      sub { my ($col, $val) = @_; push @seen, [ $col, $val ]; $val };
    };
    my $out = traced(2, sub { $_[0]->_query_async('SELECT ?', ['raw']) });
    like $out, qr/'raw'/, 'raw statement: value traced';
  }
  is_deeply \@seen, [ [ undef, 'raw' ] ], 'raw statement: the hook is given undef for the name';

  my $out = traced(1, sub {
    my ($async) = @_;
    $async->txn_do_async(sub { Future->done(1) });
  });
  like $out, qr/^BEGIN: /m, 'transaction: BEGIN traced';
  like $out, qr/^COMMIT: /m, 'transaction: COMMIT traced';
  is scalar(@K101::Debug::END), 2, 'transaction: query_end for both';
}

# k404: a select with a bind attribute runs traced at level 2 and returns rows.
{
  local @EV::Pg::ANSWER = ([ 7, 'zed', undef ]);
  local @EV::Pg::SENT;
  my @rows;
  my $out = traced(2, sub {
    my ($async, $schema) = @_;
    $schema->resultset('User')->search(
      { 'me.id' => 7, -and => [ \'me.name = ?' ] },
      { bind => [ 'zed' ] },
    )->all_async->then(sub { @rows = @_; Future->done });
  }, 'K113::Schema');
  is scalar(@rows), 1, 'select with bind attribute: one row came back';
  is $rows[0]->get_column('name'), 'zed', 'select with bind attribute: the right row';
  is_deeply $EV::Pg::SENT[-1][1], [ 'zed', 7 ], 'select with bind attribute: bare values on the wire, attribute first';
  like $out, qr/'zed', '7'/, 'select with bind attribute: both binds traced';
}

done_testing;
