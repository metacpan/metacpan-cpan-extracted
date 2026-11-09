use strict;
use warnings;
use Test::More;

# t/47-diff-view-live.t -- what only a server can answer about the views of the
# upgrade (karr k43; offline counterpart t/47-diff-view.t):
#
#   1. The comparison reads equal for a view the install made: ClickHouse
#      reformats the SELECT (quotes dropped, tables qualified with their
#      database), and a second diff must still be empty, or every upgrade
#      would replace every view.
#   2. CREATE OR REPLACE VIEW and DROP VIEW are accepted over the MySQL wire,
#      and a changed view reads back with its new columns.
#   3. A materialized view the schema does not declare is refused, by name,
#      before the first statement of the plan: nothing else of the plan ran,
#      the view and the table that holds its rows are still there.

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test;
use DBIO::ClickHouse::Deploy;

my $admin = DBIO::ClickHouse::Test->init_schema(no_deploy => 1);
my $dbh   = $admin->storage->dbh;

my $ns_count = 0;
sub mk_schema {
  my (%sources) = @_;
  my $ns = 'DBIO::ClickHouse::Test::ViewUpgrade' . ++$ns_count;
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
    $pkg->add_columns(@{ $def->{cols} });
    $pkg->set_primary_key(@{ $def->{pk} }) if $def->{pk};
  }
  eval qq{package $ns; use base 'DBIO::Schema'; 1} or die $@;
  $ns->load_components('ClickHouse');
  $ns->register_class($_, "${ns}::Result::$_") for sort keys %sources;
  return $ns->connect(DBIO::ClickHouse::Test->test_connect_info);
}

sub kind_of {
  my ($name) = @_;
  my ($engine) = $dbh->selectrow_array(
    q{SELECT engine FROM system.tables WHERE database = currentDatabase() AND name = ?},
    undef, $name);
  return $engine;
}
sub view_columns {
  my ($name) = @_;
  return join ',', map { $_->[0] } @{ $dbh->selectall_arrayref(
    q{SELECT name FROM system.columns WHERE database = currentDatabase() AND table = ? ORDER BY position},
    undef, $name) };
}

my %base = (
  Base => {
    table => 'vw_base',
    cols  => [ id => { data_type => 'integer' }, name => { data_type => 'varchar', size => 20, is_nullable => 1 } ],
    pk    => ['id'],
  },
);
sub with_view {
  my ($select, $table) = @_;
  return (%base, View => { table => $table // 'vw_view', view => $select,
    cols => [ id => { data_type => 'integer' }, name => { data_type => 'varchar', size => 20, is_nullable => 1 } ] });
}

# --- 1. + 2. install, no phantom, replace, drop -------------------------------
my $v1 = mk_schema(with_view('SELECT `id`, `name` FROM `vw_base`'));
DBIO::ClickHouse::Deploy->new(schema => $v1)->install;
is kind_of('vw_view'), 'View', 'the view is installed';
ok !DBIO::ClickHouse::Deploy->new(schema => $v1)->diff->has_changes,
  'a second diff against the same declaration is empty (the server text compares equal)';

$dbh->do('INSERT INTO vw_base (id, name) VALUES (1, \'x\')');

my $v2 = mk_schema(with_view("SELECT id, name, 1 AS one\n  FROM vw_base"));
my $diff = DBIO::ClickHouse::Deploy->new(schema => $v2)->diff;
like $diff->as_sql, qr/CREATE OR REPLACE VIEW `vw_view`/, 'a changed selection is a CREATE OR REPLACE VIEW';
DBIO::ClickHouse::Deploy->new(schema => $v2)->upgrade;
is view_columns('vw_view'), 'id,name,one', 'the view reads back with its new column';
ok !DBIO::ClickHouse::Deploy->new(schema => $v2)->diff->has_changes, '... and the diff is empty again';
is $dbh->selectrow_array('SELECT count() FROM vw_base'), 1, 'the rows of the table are untouched';

my $v3 = mk_schema(%base);
like(DBIO::ClickHouse::Deploy->new(schema => $v3)->diff->as_sql, qr/DROP VIEW (?:IF EXISTS )?`vw_view`/,
  'a view the schema no longer declares is a DROP VIEW');
DBIO::ClickHouse::Deploy->new(schema => $v3)->upgrade(allow_destructive => 1);  # the drop of the view is what is tested
is kind_of('vw_view'), undef, 'the view is gone';
ok !DBIO::ClickHouse::Deploy->new(schema => $v3)->diff->has_changes, '... and the diff is empty';

# --- 3. a materialized view holds data ----------------------------------------
$dbh->do('CREATE MATERIALIZED VIEW vw_mv ENGINE = MergeTree ORDER BY id AS SELECT id FROM vw_base');
$dbh->do('INSERT INTO vw_base (id, name) VALUES (2, \'y\')');
my ($held) = $dbh->selectrow_array('SELECT count() FROM vw_mv');
is $held, 1, 'the materialized view holds a row the table never had to give again';

my $extra = mk_schema(%base, Other => {
  table => 'vw_other', cols => [ id => { data_type => 'integer' } ], pk => ['id'] });
my $deploy = DBIO::ClickHouse::Deploy->new(schema => $extra);
my $err = do { local $@; eval { $deploy->upgrade; 1 } ? '' : "$@" };
like $err, qr/refus.*`vw_mv`.*MaterializedView/is, 'an undeclared materialized view ends the upgrade, by name';
is kind_of('vw_other'), undef, '... before the first statement: the table of the same plan was not created';
is kind_of('vw_mv'), 'MaterializedView', '... and the materialized view is still there';
is $dbh->selectrow_array('SELECT count() FROM vw_mv'), 1, '... with its rows';

my $plain = mk_schema(with_view('SELECT id, name FROM vw_base', 'vw_mv'));
$err = do { local $@; eval { DBIO::ClickHouse::Deploy->new(schema => $plain)->diff->as_sql; 1 } ? '' : "$@" };
like $err, qr/refus.*`vw_mv`/is, 'a plain view declared over its name is refused too';

$dbh->do('DROP VIEW vw_mv');
ok !DBIO::ClickHouse::Deploy->new(schema => $v3)->diff->has_changes,
  'once it is dropped by hand the upgrade has nothing left to refuse';

done_testing;
