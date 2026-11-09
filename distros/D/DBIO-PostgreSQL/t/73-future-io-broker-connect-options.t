use strict;
use warnings;
use Test::More;

# OFFLINE test: connect options beside an AccessBroker, and the fifth element
# of DBI-form connect info, on the future_io transport (karr k91).
#
# WHY: core k243 lets connect() take every connect option beside a broker,
# [ $broker, \%options ], and hands the DBD attributes and pool_size among them
# to an async backend only if its transport declares broker_connect_options --
# a promise that the transport applies them to every connection it opens. This
# transport reads the broker's answer in its own _async_broker_conninfo (kept
# over dbio-async's: it builds a Static broker's DSN without an owning sync
# storage, takes any libpq parameter and quotes values for libpq), so it has
# to keep that promise itself. And its _normalize_conninfo read only slot [3]
# of DBI-form connect info: DBD attributes or pool_size in the fifth element
# (\%extra_attributes) never reached a pooled connection, although the sync
# storage honours them.
#
# What this file claims:
#   1. the transport declares broker_connect_options, and a schema connected
#      with a broker plus DBD attributes and pool_size beside it gets its
#      future_io backend -- core no longer refuses the transport;
#   2. a DBD attribute given beside the broker reaches DBI->connect for a pool
#      connection AND the listen connection, whatever shape the broker answers
#      in (Static's libpq hash, Vault's DBI form, the transport's own shape);
#      nothing DBIO-private (async, on_connect_do, pool_size) comes along;
#   3. a setting given both beside the broker and in its answer: the same
#      value connects, a different value is refused naming the setting, and
#      nothing is sent to DBI->connect;
#   4. pool_size beside the broker sizes the pool: that many connections are
#      opened and no more;
#   5. DBI-form connect info with DBD attributes and pool_size in the fifth
#      element: the attributes reach every pooled connection (the fifth
#      element winning over the fourth, as on the sync storage), pool_size
#      sizes the pool, and no DBIO-private key reaches DBI->connect -- both on
#      the transport directly and through a schema's connect.
#
# WHAT RUNS FOR REAL: the built-in brokers, core's connect_info (option split,
# pool sizing, merge rule), the real pool, and this dist's shipped seams.
# THE SUBSTITUTIONS: DBI->connect records its arguments and hands out a fake
# handle; the Vault client is a stub.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed DBIO core predates connect options beside an AccessBroker (core k243)'
    unless DBIO::Storage::Async->can('_access_broker_call_attributes');
}

use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;

our @CONNECTS;

{
  package FakeOpts::DBH;
  sub new { bless { Active => 1, pg_socket => 42 }, shift }
  sub disconnect { $_[0]{Active} = 0; 1 }
  sub do { 1 }
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn, $user, $password, $attrs) = @_;
    push @CONNECTS, [ $dsn, $user, $password, { %$attrs } ];
    return FakeOpts::DBH->new;
  };
}

{
  package FakeVaultClient;
  sub new { bless {}, shift }
  sub read_secret { return { username => 'vault-user', password => 'vault-pw' } }
}

{
  package HashBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

{
  package OptsSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

my %FORCED = (
  AutoCommit => 1, RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1,
  # every error DBI reports for the handle is raised by the transport (karr k120)
  HandleError => \&DBIO::PostgreSQL::Storage::Async::_pg_dbi_error,
);

sub static {
  return DBIO::AccessBroker::Static->new(
    host => 'db.example', dbname => 'appdb', username => 'app', password => 's3cret', @_,
  );
}

sub vault {
  my (%attrs) = @_;
  return DBIO::AccessBroker::Vault->new(
    vault     => FakeVaultClient->new,
    dsn       => 'dbi:Pg:dbname=appdb;host=db.example',
    cred_path => 'database/creds/app',
    dbi_attrs => { async => 'future_io', %attrs },
  );
}

sub transport_with {
  my ($info) = @_;
  my $s = DBIO::PostgreSQL::Storage::Async->new(undef);
  $s->connect_info($info);
  return $s;
}

# The DBI->connect of one new pool connection (kept, so the next is new).
sub spawn {
  my ($s) = @_;
  @CONNECTS = ();
  $s->pool->acquire->get;
  return $CONNECTS[-1];
}

sub open_listen {
  my ($s) = @_;
  @CONNECTS = ();
  $s->_listen_open->get;
  return $CONNECTS[-1];
}

# ---------------------------------------------------------------------------
# 1. The declaration, and core taking it.
# ---------------------------------------------------------------------------

ok scalar(grep { $_ eq 'broker_connect_options' }
  DBIO::PostgreSQL::Storage::Async->transport_capabilities),
  'transport_capabilities declares broker_connect_options';

{
  my $schema = OptsSchema->connect(static(), {
    async => 'future_io', pg_server_prepare => 0, pool_size => 2,
  });
  my $async = eval { $schema->storage->async };
  isa_ok $async, 'DBIO::PostgreSQL::Storage::Async',
    'a schema connected with a broker plus a DBD attribute and pool_size beside it: the future_io backend'
    or diag $@;

  SKIP: {
    skip 'no backend', 3 unless $async;
    is_deeply spawn($async),
      [ 'dbi:Pg:dbname=appdb;host=db.example', 'app', 's3cret', { pg_server_prepare => 0, %FORCED } ],
      '... whose pool connection gets the attribute beside the broker, and no async';
    is_deeply open_listen($async),
      [ 'dbi:Pg:dbname=appdb;host=db.example', 'app', 's3cret', { pg_server_prepare => 0, %FORCED } ],
      '... and so does its listen connection';
    is $async->pool->max_size, 2, '... and pool_size beside the broker sized its pool';
  }
}

# ---------------------------------------------------------------------------
# 2. Each answer shape: the attribute beside the broker, pool and listen.
# ---------------------------------------------------------------------------

for my $case (
  [ 'Static (libpq hash)',
    sub { static() },
    [ 'dbi:Pg:dbname=appdb;host=db.example', 'app', 's3cret' ], {} ],
  [ 'Vault (DBI form)',
    sub { vault(pg_enable_utf8 => 1) },
    [ 'dbi:Pg:dbname=appdb;host=db.example', 'vault-user', 'vault-pw' ], { pg_enable_utf8 => 1 } ],
  [ 'DBI form with a fifth element',
    sub { HashBroker->new([ 'dbi:Pg:dbname=appdb', 'u', 'p', { pg_enable_utf8 => 1 }, { pg_bool_tf => 1 } ]) },
    [ 'dbi:Pg:dbname=appdb', 'u', 'p' ], { pg_enable_utf8 => 1, pg_bool_tf => 1 } ],
  [ "the transport's own shape",
    sub { HashBroker->new({ dsn => 'dbi:Pg:service=app', user => 'u', password => 'p',
                            attrs => { pg_enable_utf8 => 1 } }) },
    [ 'dbi:Pg:service=app', 'u', 'p' ], { pg_enable_utf8 => 1 } ],
) {
  my ($label, $build, $want_args, $answer_attrs) = @$case;
  my $s = transport_with([ $build->(),
    { pg_server_prepare => 0, async => 'future_io', on_connect_do => [ 'SET x = 1' ] } ]);
  my $want = [ @$want_args, { %$answer_attrs, pg_server_prepare => 0, %FORCED } ];

  # scalar: is_deeply has no prototype, so a bare eval that dies is an empty
  # list there -- $want is compared with the test's name, and the name is gone.
  is_deeply scalar eval { spawn($s) }, $want,
    "$label: a pool connection gets the DBD attribute beside the broker, nothing DBIO-private"
    or diag $@;
  is_deeply scalar eval { open_listen($s) }, $want,
    "$label: the listen connection gets it too"
    or diag $@;
}

# ---------------------------------------------------------------------------
# 3. A setting beside the broker and in its answer.
# ---------------------------------------------------------------------------

for my $case (
  [ 'Vault (DBI form)', sub { vault(pg_enable_utf8 => $_[0]) } ],
  [ "the transport's own shape",
    sub { HashBroker->new({ dsn => 'dbi:Pg:dbname=appdb', user => 'u', password => 'p',
                            attrs => { pg_enable_utf8 => $_[0] } }) } ],
) {
  my ($label, $build) = @$case;

  my $same = transport_with([ $build->(1), { pg_enable_utf8 => 1 } ]);
  is scalar eval { spawn($same)->[3]{pg_enable_utf8} }, 1,
    "$label: the same value beside the broker and in its answer connects"
    or diag $@;

  my $differ = transport_with([ $build->(1), { pg_enable_utf8 => 0 } ]);
  for my $open (
    [ 'a pool spawn',    sub { spawn($differ) } ],
    [ 'the listen open', sub { open_listen($differ) } ],
  ) {
    my ($where, $code) = @$open;
    @CONNECTS = ();
    my $ok  = eval { $code->(); 1 };
    my $err = $@;
    ok !$ok, "$label, different values: $where is refused";
    like $err, qr/Connection setting 'pg_enable_utf8' is given both beside the AccessBroker and in the broker's answer/,
      '... naming the setting';
    is scalar(@CONNECTS), 0, '... and nothing was sent to DBI->connect';
  }
}

# ---------------------------------------------------------------------------
# 4. pool_size beside the broker sizes the pool.
# ---------------------------------------------------------------------------

{
  my $s = transport_with([ static(), { pool_size => 3 } ]);
  is $s->pool->max_size, 3, 'pool_size 3 beside the broker: the pool is sized 3';

  @CONNECTS = ();
  my @held = map { $s->pool->acquire } 1 .. 4;
  is scalar(@CONNECTS), 3, '... four acquires open exactly three connections';
  is scalar(grep { $_->is_ready } @held), 3, '... and the fourth waits for one of them';
  ok !grep({ exists $_->[3]{pool_size} } @CONNECTS), '... pool_size is no DBD attribute';
  $s->pool->shutdown;   # settle the waiter now, not in global destruction

  is transport_with([ static() ])->pool->max_size, 5,
    'without pool_size beside the broker the pool keeps its default';
}

# ---------------------------------------------------------------------------
# 5. DBI-form connect info: the fifth element.
# ---------------------------------------------------------------------------

{
  my $s = transport_with([ 'dbi:Pg:dbname=appdb', 'u', 'p',
    { pg_enable_utf8 => 1, pg_server_prepare => 1 },
    { pg_server_prepare => 0, pool_size => 2, async => 'future_io',
      on_connect_do => [ 'SET x = 1' ], quote_names => 1 },
  ]);
  is_deeply spawn($s),
    [ 'dbi:Pg:dbname=appdb', 'u', 'p', { pg_enable_utf8 => 1, pg_server_prepare => 0, %FORCED } ],
    'DBI form, attributes in the fifth element: they reach a pooled connection, the fifth winning, nothing DBIO-private';
  is $s->pool->max_size, 2, '... and pool_size in the fifth element sizes the pool';
}

{
  my $schema = OptsSchema->connect('dbi:Pg:dbname=appdb', 'u', 'p',
    { async => 'future_io' }, { pg_server_prepare => 0, pool_size => 2 });
  my $async = $schema->storage->async;
  is_deeply spawn($async),
    [ 'dbi:Pg:dbname=appdb', 'u', 'p', { pg_server_prepare => 0, %FORCED } ],
    'through a schema connect: a DBD attribute in the fifth element reaches the pooled connection';
  is $async->pool->max_size, 2, '... and pool_size there sizes the pool';
}

done_testing;
