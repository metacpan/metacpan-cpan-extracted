use strict;
use warnings;
use Test::More;
use Future;
use DBIO::Test::Storage;
use DBIO::SQLMaker;
use DBIO::Storage::DBI;
use DBIO::Storage::Statistics;

# Karr k53: the trace of the transport runs through the debug object of the
# owning storage and its redact_bind_value hook (core ADR 0025), like the sync
# path. DBIO_TRACE=1 shows the SQL, from 2 on the binds, each cut to 32
# characters after redaction. Nothing goes to STDERR through warn.

{
  package TraceMock;
  use base 'DBIO::Async::Storage';

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready         { 1 }
  sub _create_pool_connection   { { wire => [] } }
  sub _shutdown_pool_connection { }
  sub _await_readable     { Future->new }
  sub _submit_query       { }
  sub _collect_result     { Future->done([]) }
}

{
  # Stands in for the sync storage that owns the backend.
  package TraceOwner;
  use DBIO::Storage::Statistics;
  sub new {
    my ($class, $redact) = @_;
    my $out = '';
    open my $fh, '>', \$out or die $!;
    my $stats = DBIO::Storage::Statistics->new;
    $stats->debugfh($fh);
    return bless { out => \$out, stats => $stats, redact => $redact }, $class;
  }
  sub debugobj { $_[0]{stats} }
  sub redact_bind_value { $_[0]{redact} }
  sub output { ${ $_[0]{out} } }
}

my $SECRET = 'tok-SECRET-123';
my $LONG   = 'x' x 40;
my @bind   = ('bob', $SECRET, undef, $LONG);
my $sql    = 'INSERT INTO users (name, token, note, bio) VALUES (?, ?, ?, ?)';

my $stderr = '';
local $SIG{__WARN__} = sub { $stderr .= $_[0] };

# Runs one statement of the given kind and returns what the owner traced.
sub traced {
  my ($level, $kind, $redact) = @_;
  my $owner   = TraceOwner->new($redact // sub { $_[1] });
  my $storage = TraceMock->new(undef);
  $storage->connect_info([{ host => 'localhost' }]);
  $storage->_owner_storage($owner);
  $storage->{debug} = $level;
  my $f = $kind eq 'pooled'
    ? $storage->_query_async($sql, [@bind])
    : $storage->_query_async_pinned({}, $sql, [@bind]);
  return $owner->output;
}

for my $kind (qw( pooled pinned )) {
  my $out = traced(1, $kind);
  like $out, qr/^\Q$sql\E: \n\z/, "$kind, DBIO_TRACE=1: SQL is traced, without binds";
  unlike $out, qr/\Q$SECRET\E|bob/, "$kind, DBIO_TRACE=1: no bind value in the output";

  $out = traced(2, $kind, sub { $_[1] eq $SECRET ? '***' : $_[1] });
  like $out, qr/'bob', '\*\*\*', NULL, '/, "$kind, level 2: binds traced, NULL as NULL";
  unlike $out, qr/\Q$SECRET\E/, "$kind, level 2: the redactor hides the secret";
  like $out, qr/'x{32}\.\.\.'/, "$kind, level 2: a value is cut to 32 characters";
  unlike $out, qr/x{33}/, "$kind, level 2: nothing longer than the cut";

  # Redact first, then cut: a redactor sees the whole value.
  my @seen;
  traced(2, $kind, sub { push @seen, $_[1]; $_[1] });
  ok scalar(grep { $_ eq $LONG } @seen), "$kind: the redactor is handed the whole value";

  like traced('2=/some/path', $kind), qr/'bob'/, "$kind: '2=/path' is level 2";
  unlike traced('1=/some/path', $kind), qr/bob/, "$kind: '1=/path' is level 1";
}

# Without an owner the storage's own debug object is used, and the class-level
# hook of DBIO::Storage::DBI redacts.
{
  require DBIO::Storage::DBI;
  my $owner   = TraceOwner->new;
  my $storage = TraceMock->new(undef);
  $storage->connect_info([{ host => 'localhost' }]);
  $storage->debugobj($owner->debugobj);
  $storage->{debug} = 2;
  local *DBIO::Storage::DBI::redact_bind_value = sub { sub { 'masked' } };
  $storage->_query_async($sql, [@bind]);
  like $owner->output, qr/'masked', 'masked', NULL, 'masked'/,
    'no owner: own debug object, class-level redactor';
}

# --- core k402 / k404: name and attributes, query_end, a select with bind ---

{
  package T38::Schema::Result::User;
  use base 'DBIO::Core';
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    name     => { data_type => 'varchar', size => 64, is_nullable => 1 },
    password => { data_type => 'varchar', size => 255, is_nullable => 1, encode_column => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package T38::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(User => 'T38::Schema::Result::User');
}

{
  # query_start / query_end are recorded, in the order they happen.
  package T38::Stats;
  our @ISA = ('DBIO::Storage::Statistics');
  our @log;
  sub query_start { my $s = shift; push @log, 'start'; $s->SUPER::query_start(@_) }
  sub query_end   { my $s = shift; push @log, 'end';   $s->SUPER::query_end(@_) }
}

{
  # The poll is the test's: it settles when the test says so.
  package T38::Mock;
  use base 'DBIO::Async::Storage';

  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready      { 1 }
  sub _create_pool_connection   { { wire => [] } }
  sub _shutdown_pool_connection { }
  sub _submit_query    { }
  sub _await_readable  { my $self = shift; push @{ $self->{polls} }, my $f = Future->new; $f }
  sub _collect_result  {
    my $self = shift;
    return $self->{collect_fail} ? Future->fail("boom\n") : Future->done($self->{rows} || []);
  }
}

T38::Schema->storage_type('+DBIO::Test::Storage');
my $schema = T38::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));
my $owner  = $schema->storage;
my $source = $schema->source('User');

sub t38_backend {
  my ($level) = @_;
  my $b = T38::Mock->new($schema);
  $b->connect_info([{ host => 'localhost' }]);
  $b->_owner_storage($owner);
  $owner->_async_context_owner_token($b->_context_owner_token);
  $b->{debug} = $level;
  my $out = '';
  open my $fh, '>', \$out or die $!;
  my $stats = T38::Stats->new;
  $stats->debugfh($fh);
  $owner->debugobj($stats);
  return ($b, \$out);
}

# Settle the polls of a backend, so the statements see their result.
sub t38_settle {
  my ($b) = @_;
  $_->done for grep { !$_->is_ready } @{ $b->{polls} || [] };
}

for my $kind (qw( pooled pinned )) {
  my $runner = sub {
    my ($b) = @_;
    return $kind eq 'pooled' ? $b->_pool_runner : $b->_pinned_runner({ wire => [] });
  };

  # (a) encode_column shows as *** from the attributes core builds.
  {
    my ($b, $out) = t38_backend(2);
    $b->_run_crud(insert => $runner->($b), $source, { name => 'alice', password => 'hunter2-secret' });
    like $$out, qr/'alice'/, "$kind: a plain column is traced at level 2";
    like $$out, qr/'\*\*\*'/, "$kind: an encode_column bind is traced as ***";
    unlike $$out, qr/hunter2/, "$kind: the encoded value is not traced";
  }

  # (b) a hook of the owner sees the column name and the attributes.
  {
    my ($b) = t38_backend(2);
    my @asked;
    my $old = DBIO::Storage::DBI->redact_bind_value;
    DBIO::Storage::DBI->redact_bind_value(sub { push @asked, [@_]; $_[1] });
    $b->_run_crud(delete => $runner->($b), $source, { name => 'bob' });
    DBIO::Storage::DBI->redact_bind_value($old);
    is $asked[0][0], 'name', "$kind: the hook sees the column name";
    is $asked[0][1], 'bob', "$kind: the hook sees the value";
    is ref $asked[0][2], 'HASH', "$kind: the hook sees the attribute hash";
  }

  # (c) level 1 shows no binds.
  {
    my ($b, $out) = t38_backend(1);
    $b->_run_crud(insert => $runner->($b), $source, { name => 'alice', password => 'hunter2-secret' });
    like $$out, qr/INSERT INTO/, "$kind: level 1 traces the statement";
    unlike $$out, qr/alice|hunter2|\*\*\*/, "$kind: level 1 shows no binds";
  }

  # (e) a select with a bind attribute, traced at level 2, yields its rows.
  {
    my ($b, $out) = t38_backend(2);
    $b->{rows} = [[ 5, 'zed' ]];
    my $ra = $schema->resultset('User')->search(
      { 'me.id' => 5, -and => [ \'me.name = ?' ] },
      { bind => [ 'zed' ] },
    )->_resolved_attrs;
    my $f = $b->_run_crud(select => $runner->($b), $ra->{from}, $ra->{select}, $ra->{where}, $ra);
    t38_settle($b);
    ok $f->is_ready && !$f->failure, "$kind: a select with a bind attribute completes with trace on";
    is_deeply [ $f->get ], [ [[ 5, 'zed' ]] ], "$kind: it yields the rows";
    like $$out, qr/'zed', '5'/, "$kind: the bind attribute value stands first in the trace";
  }

  # (f) query_end runs once the statement is done, on success and on failure,
  # and not before.
  for my $fail (0, 1) {
    my ($b) = t38_backend(1);
    $b->{collect_fail} = $fail;
    @T38::Stats::log = ();
    my $f = $kind eq 'pooled'
      ? $b->_query_async('SELECT 1', [])
      : $b->_query_async_pinned({ wire => [] }, 'SELECT 1', []);
    is_deeply \@T38::Stats::log, ['start'], "$kind: no query_end while the statement is in flight";
    t38_settle($b);
    ok $f->is_ready, "$kind: the future is ready";
    is_deeply \@T38::Stats::log, [qw(start end)],
      "$kind: query_end ran once the statement " . ($fail ? 'failed' : 'succeeded');
    $f->failure if $fail;
  }

  # query_end also runs for a statement cancelled in flight.
  {
    my ($b) = t38_backend(1);
    @T38::Stats::log = ();
    my $f = $kind eq 'pooled'
      ? $b->_query_async('SELECT 1', [])
      : $b->_query_async_pinned({ wire => [] }, 'SELECT 1', []);
    $f->cancel;
    is_deeply \@T38::Stats::log, [qw(start end)], "$kind: query_end ran for a cancelled statement";
  }
}

# (d) a raw statement gives the hook undef for name and attributes.
{
  my ($b) = t38_backend(2);
  my @asked;
  my $old = DBIO::Storage::DBI->redact_bind_value;
  DBIO::Storage::DBI->redact_bind_value(sub { push @asked, [@_]; $_[1] });
  $b->_query_async_pinned({ wire => [] }, 'BEGIN', ['x']);
  DBIO::Storage::DBI->redact_bind_value($old);
  is_deeply \@asked, [[ undef, 'x', undef ]], 'a raw statement: undef name and attributes';
}

is $stderr, '', 'nothing went to STDERR through warn';

done_testing;
