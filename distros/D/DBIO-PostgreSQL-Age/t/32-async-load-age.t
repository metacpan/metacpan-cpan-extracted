use strict;
use warnings;
use Test::More;

# karr #5 + core karr #68: LOAD 'age' (and the ag_catalog search_path SET) must
# fire on EVERY freshly-spawned async pool connection, replayed through the core
# pool on_connect seam -- NOT via any per-adapter hack in the async transport
# (that would be the karr #66 anti-pattern). This proves it end-to-end, offline:
#
#   * owner  = the composed SYNC Age storage (the Age storage LAYER over the PG
#     driver storage). It defines connect_call_load_age via the layer -- the
#     async layer deliberately does NOT;
#   * backend = a REAL composed Age async backend (the Age async LAYER over the
#     future_io transport) whose pool is swapped for a recording pool (no DBD::Pg
#     connect, no event loop);
#   * connect_info carries { on_connect_call => 'load_age' }.
#
# Acquiring a pool connection must record exactly the two statements
# connect_call_load_age emits, against that connection, before it is served.
# Mirrors core t/storage/pool_connect_actions.t.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all => 'future_io prerequisites (DBD::Pg/Future/Future::IO) not available';
}

use DBIO::Test;
use DBIO::Storage::Composed;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Age::Storage;
use DBIO::PostgreSQL::Age::Storage::Async;

# --- Recording connection: the { dbh => $dbh } shape the default runner drives -
{
  package RecHandle;
  sub new { bless { log => $_[1] }, $_[0] }
  sub do  { my ($self, $sql) = @_; push @{ $self->{log} }, $sql; 1 }
}

{
  package RecPool;
  use base 'DBIO::Storage::PoolBase';

  my $NEXT = 0;
  sub _create_connection {
    my @log;
    return { id => ++$NEXT, log => \@log, dbh => RecHandle->new(\@log) };
  }
  sub _shutdown_connection { }   # keep the log alive for post-shutdown asserts
}

# --- The real Age async backend, with its pool swapped for the recorder -------
# The composed backend's ISA is (Age async layer, future_io transport); we
# reconstruct exactly that here and swap in the recording pool.
{
  package RecAgeBackend;
  use base qw( DBIO::PostgreSQL::Age::Storage::Async DBIO::PostgreSQL::Storage::Async );
  use mro 'c3';

  # The transport's reset (ADR 0079, dbio-postgresql k154): DISCARD ALL, then
  # the connect actions again through the core seam. Stubbed here because the
  # recording handle is not a DBD::Pg handle the transport can drive; the
  # replay itself is the real _setup_pool_connection.
  sub _reset_pool_connection {
    my ($self, $conn) = @_;
    $conn->{dbh}->do('DISCARD ALL');
    $self->_setup_pool_connection($conn);
    return $self->future_class->done;
  }

  sub pool {
    my $self = shift;
    $self->{pool} ||= RecPool->new(
      storage  => $self,
      conninfo => 'fake',
      size     => $self->{_pool_size} || 2,
    );
  }
}

my $schema = DBIO::Test->init_schema;   # kept alive: storages weaken their refs

# The owning SYNC storage is the composed Age storage (Age LAYER over the PG
# driver) -- it carries connect_call_load_age via the layer.
my $owner_class = DBIO::Storage::Composed->compose(
  'DBIO::PostgreSQL::Storage', ['DBIO::PostgreSQL::Age::Storage'],
);
my $owner   = $owner_class->new($schema);
my $backend = RecAgeBackend->new($schema);

$owner->on_connect_call('load_age');
$backend->_owner_storage($owner);
$backend->connect_info([ { host => 'h', pool_size => 2 } ]);

# karr k18: ag_catalog is put in FRONT of the connection's search_path, not set
# over it (a tenant schema from the driver's connect-time seam must survive);
# a path that already holds ag_catalog anywhere is left as it is.
my @expected = ( q{LOAD 'age'}, qr/^SELECT set_config\('search_path'.*\(\^\|,\).*ag_catalog.*THEN current_setting\('search_path'\).*'ag_catalog, ' \|\| current_setting\('search_path'\)/ );

sub log_is {
  my ($log, $name) = @_;
  my $ok = @$log == 2 && $log->[0] eq $expected[0] && $log->[1] =~ $expected[1];
  ok $ok, $name or diag explain $log;
}

# --- A freshly spawned connection replays load_age via the core seam ----------
{
  my $c1 = $backend->pool->acquire->get;
  log_is $c1->{log},
    q{connect_call_load_age replayed on the first pool connection: LOAD 'age' then the search_path SET};

  ok scalar(@{ $c1->{log} }),
    'the LOAD/SET are in place the moment the connection is handed out (spawn-time, pre-query)';

  # A second physical connection gets its OWN independent replay.
  my $c2 = $backend->pool->acquire->get;
  isnt $c1->{id}, $c2->{id}, 'two distinct physical connections spawned';
  log_is $c2->{log},
    'the second pool connection got its own full load_age replay';

  # A returned connection is reset (DISCARD ALL wipes LOAD and search_path)
  # and the connect actions run again before it is handed out a second time.
  $backend->pool->release($c1);
  my $reused = $backend->pool->acquire->get;
  is $reused->{id}, $c1->{id}, 'released connection is reused after its reset, not re-spawned';
  my @log = @{ $reused->{log} };
  is $log[2], 'DISCARD ALL', 'the reset ran on release, after the spawn-time replay';
  is scalar(@log), 5, 'reset plus a full second load_age replay, nothing more';
  is $log[3], $expected[0], 'LOAD age runs again after the reset';
  like $log[4], $expected[1], 'the ag_catalog search_path SET runs again after the reset';
}

# --- karr k24: with a tenant namespace (connect key `schema`) ag_catalog is
# inserted BEHIND the namespace entry, not in front. The owner's
# connection_schema decides; the replay on the pool connection follows it.
{
  $owner->connection_schema('tenant_a');
  my $tb = RecAgeBackend->new($schema);   # own pool: the first one is full
  $tb->_owner_storage($owner);
  $tb->connect_info([ { host => 'h', pool_size => 2 } ]);
  my $fresh = $tb->pool->acquire->get;
  is scalar(@{ $fresh->{log} }), 3, 'tenant: three statements replayed';
  like $fresh->{log}[0], qr/^SET search_path TO tenant_a\b/,
    'tenant: the driver sets the namespace path first (core runs it ahead of on_connect_call)';
  is $fresh->{log}[1], q{LOAD 'age'}, 'tenant: LOAD age replayed';
  like $fresh->{log}[2], qr/regexp_replace\(current_setting\('search_path'\).*, ag_catalog'\)/,
    'tenant: the replayed path statement inserts ag_catalog behind the first element';
  unlike $fresh->{log}[2], qr/'ag_catalog, ' \|\|/,
    'tenant: ag_catalog is not prepended';
  $owner->connection_schema(undef);
}

# --- The adapter itself owns NO load_age logic (anti-hack guard) --------------
{
  ok( !DBIO::PostgreSQL::Age::Storage::Async->can('connect_call_load_age'),
    'the async adapter defines no connect_call_load_age of its own -- LOAD age '
    . q{comes only from the owning sync storage via the core seam (no per-adapter hack)} );

  ok( DBIO::PostgreSQL::Age::Storage->can('connect_call_load_age'),
    'the owning sync Age storage is where connect_call_load_age actually lives' );
}

done_testing;
