# ABSTRACT: the extension activation seams of a connection (ADR 0066, karr k347)
use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;

# CLAIM: core's _apply_connection_schema asks the driver what the declared
# extensions want of a new connection (_extension_activation), has the driver
# write it (_activate_extensions) and only then sets the namespace
# (_set_connection_schema, handed the activation). A driver that declares none
# of this keeps today's behaviour exactly. Sync connect and async pool
# connection go through the same method.
#
# The second half measures that a driver which overrides only the two new
# seams (+ _set_connection_schema) sends the same statements, in the same
# order, as one that replaces _apply_connection_schema as a whole: LOAD first,
# then the search_path; without a namespace the activation is only appended.

my @conn = ('dbi:Karr347:db=t', 'user', 'pass');

# --- a recording driver: every seam logs its call and its arguments ---------
{
  package Karr347::Rec;
  use base 'DBIO::Test::Storage';
  our (@LOG, $ACTIVATION);
  sub _extension_activation  { push @LOG, "activation(" . ($_[1] // 'undef') . ')'; $ACTIVATION }
  sub _activate_extensions   { push @LOG, "activate(" . join(',', @{ $_[1]{load} }) . ";" . ($_[2] // 'undef') . ')' }
  sub _set_connection_schema { push @LOG, "set($_[1];" . (ref $_[2] ? 'activation' : 'undef') . ')' }
  sub connect_call_rec       { push @LOG, 'on_connect_call' }
}

sub rec {
  my ($activation, %attrs) = @_;
  @Karr347::Rec::LOG = ();
  $Karr347::Rec::ACTIVATION = $activation;
  my $s = Karr347::Rec->new;
  $s->connect_info([ @conn, { on_connect_call => 'rec', %attrs } ]);
  return $s;
}

# --- the defaults: no activation, nothing written ---------------------------
{
  my $plain = DBIO::Test::Storage->new;
  $plain->connect_info([ @conn ]);
  is $plain->_extension_activation('x'), undef, '_extension_activation default: no activation';
  is $plain->_activate_extensions({ load => ['age'] }, 'x'), $plain, '_activate_extensions default does nothing';

  my $named = DBIO::Test::Storage->new;
  $named->connect_info([ @conn, { schema => 'tenant' } ]);
  eval { $named->_run_connection_actions };
  like $@, qr/has no namespaces/, 'a driver without any of it still refuses the schema key';
}

# --- sync: activation, activate, set namespace, then the user's actions ------
{
  my $act = { load => ['age'], search_path => ['ag_catalog'] };
  rec($act, schema => 'tenant')->_run_connection_actions;
  is_deeply \@Karr347::Rec::LOG,
    [ 'activation(tenant)', 'activate(age;tenant)', 'set(tenant;activation)', 'on_connect_call' ],
    'with an activation and a namespace: asked, written, namespace set with the activation, then on_connect_call';

  rec($act)->_run_connection_actions;
  is_deeply \@Karr347::Rec::LOG,
    [ 'activation(undef)', 'activate(age;undef)', 'on_connect_call' ],
    'without a namespace: the activation is written, the namespace seam is not asked';

  rec(undef, schema => 'tenant')->_run_connection_actions;
  is_deeply \@Karr347::Rec::LOG,
    [ 'activation(tenant)', 'set(tenant;undef)', 'on_connect_call' ],
    'no activation: nothing is activated, the namespace seam gets no activation';

  rec(undef)->_run_connection_actions;
  is_deeply \@Karr347::Rec::LOG, [ 'activation(undef)', 'on_connect_call' ],
    'no activation and no namespace: only the question is asked';
}

# --- the async pool connection goes through the same method ------------------
{
  my $act = { load => ['age'], search_path => ['ag_catalog'] };
  my $s = rec($act, schema => 'tenant_b');
  $s->_run_pool_connect_actions(sub { push @Karr347::Rec::LOG, 'runner' });
  is_deeply \@Karr347::Rec::LOG,
    [ 'activation(tenant_b)', 'activate(age;tenant_b)', 'set(tenant_b;activation)', 'on_connect_call' ],
    'pool connection replay: same seams, same order';
}

# --- measurement: two seams replace the driver's _apply_connection_schema ----
{
  package Karr347::PgShared;
  use base 'DBIO::Test::Storage';
  our @SQL;
  sub _do_query { push @SQL, $_[1]; $_[0] }
  sub _extension_activation { { load => ['age'], search_path => ['ag_catalog'] } }
  sub _set_connection_schema {
    my ($self, $name, $activation) = @_;
    $self->_do_query('SET search_path TO ' . join ', ',
      map { qq{"$_"} } $name, 'public', @{ ($activation // {})->{search_path} || [] });
    return $self;
  }
  sub _quote_literal { my $v = $_[1]; $v =~ s/'/''/g; "'$v'" }

  # What the driver does today: replaces the whole method.
  package Karr347::PgOld;
  use base 'Karr347::PgShared';
  sub _apply_connection_schema {
    my ($self) = @_;
    my $name = $self->connection_schema;
    my $activation = $self->_extension_activation($name);

    $self->_do_query('LOAD ' . $self->_quote_literal($_)) for @{ $activation->{load} };

    if (defined $name) {
      $self->_set_connection_schema($name, $activation);
    }
    elsif (my @path = @{ $activation->{search_path} }) {
      my $add = join ', ', map { qq{"$_"} } @path;
      $self->_do_query(
        q{SELECT pg_catalog.set_config('search_path', pg_catalog.current_setting('search_path') || }
        . $self->_quote_literal(", $add") . ', false)');
    }
    return $self;
  }

  # What it becomes: the dialect part only, core keeps the order.
  package Karr347::PgNew;
  use base 'Karr347::PgShared';
  sub _activate_extensions {
    my ($self, $activation, $name) = @_;
    $self->_do_query('LOAD ' . $self->_quote_literal($_)) for @{ $activation->{load} };
    if (!defined $name and my @path = @{ $activation->{search_path} }) {
      my $add = join ', ', map { qq{"$_"} } @path;
      $self->_do_query(
        q{SELECT pg_catalog.set_config('search_path', pg_catalog.current_setting('search_path') || }
        . $self->_quote_literal(", $add") . ', false)');
    }
    return $self;
  }
}

sub statements {
  my ($class, $path, %attrs) = @_;
  @Karr347::PgShared::SQL = ();
  my $s = $class->new;
  $s->connect_info([ @conn, { %attrs } ]);
  $path eq 'sync' ? $s->_run_connection_actions : $s->_run_pool_connect_actions(sub { });
  return [ @Karr347::PgShared::SQL ];
}

for my $case ([ 'with a namespace', schema => 'tenant' ], [ 'without a namespace' ]) {
  my ($label, @attrs) = @$case;
  for my $path (qw(sync pool)) {
    my $old = statements('Karr347::PgOld', $path, @attrs);
    my $new = statements('Karr347::PgNew', $path, @attrs);
    is_deeply $new, $old, "$path, $label: the two seams send what _apply_connection_schema sent";
  }
}

is_deeply statements('Karr347::PgNew', 'sync', schema => 'tenant'),
  [ q{LOAD 'age'}, q{SET search_path TO "tenant", "public", "ag_catalog"} ],
  'with a namespace: LOAD first, then the search_path';
is_deeply statements('Karr347::PgNew', 'sync'),
  [ q{LOAD 'age'},
    q{SELECT pg_catalog.set_config('search_path', pg_catalog.current_setting('search_path') || ', "ag_catalog"', false)} ],
  'without a namespace: LOAD, then the activation is only appended';

done_testing;
