use strict;
use warnings;
use Test::More;

# t/52-view-order-live.t -- what only a server can answer about the order of
# views (karr k43; offline counterpart t/52-view-order.t):
#
#   1. a view over a view whose name sorts AFTER its own installs, in a database
#      of this file's own, and the diff against the same declaration is empty
#      (the scratch deploy built the target in the same order);
#   2. the upgrade creates a three-deep chain in order, replaces a changed base
#      view with its readers present, and drops the chain reader-first, each
#      statement accepted by the server;
#   3. a cycle ends the install before its first statement.
#
# The database is this file's own (dbio_vorder_<pid>), created and dropped here.

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test;
use DBIO::ClickHouse::Deploy;
use DBIO::ClickHouse::DDL::Emit qw(create_database drop_database);

my $admin = DBIO::ClickHouse::Test->init_schema(no_deploy => 1);
my $dbh   = $admin->storage->dbh;

my $own = "dbio_vorder_$$";
$dbh->do(drop_database(name => $own, if_exists => 1));
$dbh->do(create_database(name => $own));
END { eval { DBI->connect($ENV{DBIO_TEST_CLICKHOUSE_DSN}, $ENV{DBIO_TEST_CLICKHOUSE_DBUSER},
  $ENV{DBIO_TEST_CLICKHOUSE_DBPASS}, { RaiseError => 1 })->do(drop_database(name => $own, if_exists => 1)) } }

my $ns_count = 0;
# %sources: name => { table, view (select, optional) }
sub mk_schema {
  my (%sources) = @_;
  my $ns = 'DBIO::ClickHouse::Test::ViewOrder' . ++$ns_count;
  for my $name (sort keys %sources) {
    my $def = $sources{$name};
    my $pkg = "${ns}::Result::$name";
    eval qq{package $pkg; use base 'DBIO::Core'; 1} or die $@;
    $pkg->load_components('ClickHouse::Result');
    if ($def->{view}) {
      $pkg->table_class('DBIO::ResultSource::View');
      $pkg->table($def->{table});
      $pkg->result_source_instance->view_definition($def->{view});
      $pkg->result_source_instance->is_virtual(0);
    }
    else {
      $pkg->table($def->{table});
    }
    $pkg->add_columns(id => { data_type => 'integer' });
    $pkg->set_primary_key('id') unless $def->{view};
  }
  eval qq{package $ns; use base 'DBIO::Schema'; 1} or die $@;
  $ns->load_components('ClickHouse');
  $ns->register_class($_, "${ns}::Result::$_") for sort keys %sources;
  return $ns->connect(DBIO::ClickHouse::Test->test_connect_info);
}
sub views_here {
  return join ',', map { $_->[0] } @{ $dbh->selectall_arrayref(
    q{SELECT name FROM system.tables WHERE database = currentDatabase() AND engine = 'View' AND name LIKE 'vo\_%' ORDER BY name}) };
}
# every object this file makes is in the connected database under vo_: dropped here
sub clean { $dbh->do("DROP VIEW IF EXISTS `$_`") for qw(vo_a_top vo_m_mid vo_z_low); $dbh->do('DROP TABLE IF EXISTS vo_base') }
END { eval { clean() } }
clean();

my %chain = (
  Base => { table => 'vo_base' },
  A_Top => { table => 'vo_a_top', view => 'SELECT id FROM vo_m_mid' },
  M_Mid => { table => 'vo_m_mid', view => 'SELECT id FROM vo_z_low' },
  Z_Low => { table => 'vo_z_low', view => 'SELECT id FROM vo_base' },
);

# --- 1. install, then an empty diff -------------------------------------------
my $schema = mk_schema(%chain);
DBIO::ClickHouse::Deploy->new(schema => $schema)->install;
is views_here(), 'vo_a_top,vo_m_mid,vo_z_low', 'the chain installs although the reader sorts before what it reads';
ok !DBIO::ClickHouse::Deploy->new(schema => $schema)->diff->has_changes,
  'a diff against the same declaration is empty (the scratch deploy used the same order)';

# --- 2. upgrade: replace the base view with its readers present, then drop ----
my $changed = mk_schema(%chain, Z_Low => { table => 'vo_z_low', view => 'SELECT id, 1 AS one FROM vo_base' });
my $up = DBIO::ClickHouse::Deploy->new(schema => $changed);
my $diff = $up->diff;
ok $diff->has_changes, 'a changed base view is a change';
$up->apply($diff);
ok !DBIO::ClickHouse::Deploy->new(schema => $changed)->diff->has_changes, '... applied, the next diff is empty';

my $bare = mk_schema(Base => $chain{Base});
my $drop = DBIO::ClickHouse::Deploy->new(schema => $bare);
my $dropdiff = $drop->diff;
my @drops = $dropdiff->as_sql =~ /DROP VIEW (?:IF EXISTS )?`([^`]+)`/g;
is_deeply \@drops, [qw(vo_a_top vo_m_mid vo_z_low)], 'the chain is dropped reader first';
$drop->apply($dropdiff, allow_destructive => 1);  # the drops are what is tested
is views_here(), '', '... and the server took every statement';

# --- 3. cycle ------------------------------------------------------------------
my $cyc = mk_schema(
  Base => $chain{Base},
  A    => { table => 'vo_a_top', view => 'SELECT id FROM vo_m_mid' },
  B    => { table => 'vo_m_mid', view => 'SELECT id FROM vo_a_top' },
);
clean();
my $err = do { local $@; eval { DBIO::ClickHouse::Deploy->new(schema => $cyc)->install; 1 } ? '' : "$@" };
like $err, qr/refus.*cycle.*`vo_a_top`.*`vo_m_mid`/is, 'a cycle is refused, naming both views';
is scalar $dbh->selectrow_array(q{SELECT count() FROM system.tables WHERE database = currentDatabase() AND name = 'vo_base'}), 0,
  '... before the first statement: the table was not made';

done_testing;
