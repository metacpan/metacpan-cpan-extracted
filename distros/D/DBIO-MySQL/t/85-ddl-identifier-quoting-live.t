use strict;
use warnings;
use Test::More;

# LIVE half of karr k77: a schema whose tables, columns, keys and indexes are
# named with reserved words, with a hyphen or with a backtick is installed by
# DBIO::MySQL::Deploy->install and upgraded by ->upgrade.
#
# WHY IT MATTERS. t/32 has the reason and pins the statements. Whether those
# statements are what a server accepts -- that `order` in backticks is a table
# and not a syntax error, that a doubled backtick is how a name with a backtick
# is written -- only a server can say, and MySQL and MariaDB each say it for
# themselves. Before k77 the first CREATE TABLE of this schema was refused
# with 1064, on install and, since a diff installs the schema into a temporary
# database first, on every upgrade as well.
#
# What this file claims:
#   1. install runs, and the server then has every table, column, key, index,
#      foreign key and view under exactly the name the schema gives it;
#   2. rows go into those tables and come back through the view, through the
#      resultsets: the names install created are the names a query asks for;
#   3. upgrade runs every kind of statement a diff writes over such names --
#      a table created with its primary and foreign key and dropped, a column
#      added, changed and dropped, an index created and dropped, a foreign key
#      added and dropped -- and the server has the result;
#   4. after install and after every upgrade the next diff has nothing left,
#      so the introspection reads those names back as they are.
#
# NOT claimed, and the schema is built to stay clear of it, because it is
# another card's:
#   - the order of the tables in the install DDL (karr k84): a moniker here
#     sorts after the one its table references;
#   - DEFAULT in a diff (karr k78), and a nullable column an upgrade adds or
#     changes, which t/88 asks (karr k87): every column an upgrade adds or
#     changes here is NOT NULL and has no default;
#   - a column leaving together with its index (karr k80), which t/87 asks:
#     the column dropped here has none;
#   - text columns of a table an upgrade creates (karr k82): the one created
#     here has numbers only.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in a database of its own, created and dropped here: upgrade() is a
# statement about a whole database -- it drops every table the schema does not
# name -- and the database the DSN names is shared with the rest of the suite.
# The account has to be allowed CREATE DATABASE, which a diff needs anyway for
# its temporary database (_dbio_tmp_*, probed up front: karr k105).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use DiffTempDbProbe qw(temp_db_skip_reason);

my $DB = "dbio_k77_$$";

my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
my ($dbd) = $dsn =~ /\Adbi:(\w+):/;

sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
END {
  if ($raw) {
    local ($@, $?);
    eval { drop_database() };
  }
}

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own, and a diff needs one too: $why";
}
if (my $why = temp_db_skip_reason($raw)) { plan skip_all => $why }
note sprintf 'server %s, DBD::%s %s, database %s', scalar $raw->selectrow_array('SELECT VERSION()'),
  $dbd, "DBD::$dbd"->VERSION, $DB;

# ---------------------------------------------------------------------------
# The schema, in the versions it goes through
# ---------------------------------------------------------------------------
# Every name is one the server takes only in backticks: a reserved word
# (group, key, order, select, from, where, having, like, drop, index, rank,
# desc, table, unique), a name with a hyphen (my-col), a name with a backtick
# (we`ird, ti`ck). An accessor is given wherever the name of the column is a
# method of a result class already, or cannot be the name of one.
my @GROUP_COLUMNS = (
  key => { data_type => 'int', is_auto_increment => 1, accessor => 'group_key' },
);
my @ORDER_COLUMNS = (
  id       => { data_type => 'int', is_auto_increment => 1 },
  key      => { data_type => 'varchar', size => 20, accessor => 'order_key' },
  group    => { data_type => 'int', accessor => 'group_id' },
  'my-col' => { data_type => 'int', accessor => 'my_col' },
  'we`ird' => { data_type => 'int', is_nullable => 1, accessor => 'weird' },
);
# `order` after the first upgrade: my-col wider, and two columns more.
my @ORDER_COLUMNS_2 = (
  id       => { data_type => 'int', is_auto_increment => 1 },
  key      => { data_type => 'varchar', size => 20, accessor => 'order_key' },
  group    => { data_type => 'int', accessor => 'group_id' },
  'my-col' => { data_type => 'bigint', accessor => 'my_col' },
  'we`ird' => { data_type => 'int', is_nullable => 1, accessor => 'weird' },
  drop     => { data_type => 'int', accessor => 'dropped' },
  select   => { data_type => 'int', accessor => 'selected' },
);
# ... and after the second: without the column `drop`.
my @ORDER_COLUMNS_3 = @ORDER_COLUMNS_2;
splice @ORDER_COLUMNS_3, 10, 2;

my @SELECT_COLUMNS = (
  id   => { data_type => 'int', is_auto_increment => 1 },
  from => { data_type => 'int', is_nullable => 1, accessor => 'from_id' },
);
my @TABLE_COLUMNS = (
  key     => { data_type => 'int', is_auto_increment => 1, accessor => 'table_key' },
  order   => { data_type => 'int', accessor => 'order_id' },
  'ti`ck' => { data_type => 'int', accessor => 'tick' },
);

# One version of the schema, connected to the database of this test:
#   Moniker => { table => ..., columns => [...], pk => ...,
#                unique => { name => [columns] },    # add_unique_constraint
#                index  => { name => [columns] },    # mysql_index
#                fk     => [ column => Moniker => its column ],   # belongs_to
#                view   => 'SELECT ...' }            # a view instead of a table
# install_ddl writes the tables in the order of their monikers and a foreign
# key into its CREATE TABLE (karr k84), so a moniker sorts after the one it
# references: Group, Order, Select, Table.
my $version = 0;
sub schema_version {
  my (%sources) = @_;
  my $ns = 'K77Live::V' . ++$version;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $moniker (sort keys %sources) {
    my $def   = $sources{$moniker};
    my $class = "${ns}::Result::$moniker";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table_class('DBIO::ResultSource::View') if $def->{view};
    $class->table($def->{table});
    $class->result_source_instance->view_definition($def->{view}) if $def->{view};
    $class->add_columns(@{ $def->{columns} });
    $class->set_primary_key($def->{pk}) if $def->{pk};
    $class->add_unique_constraint($_ => $def->{unique}{$_}) for sort keys %{ $def->{unique} // {} };
    $class->mysql_index($_ => { columns => $def->{index}{$_} }) for sort keys %{ $def->{index} // {} };
    if (my $fk = $def->{fk}) {
      my ($column, $to, $to_column) = @$fk;
      $class->belongs_to("rel_$to" => "${ns}::Result::$to", { "foreign.$to_column" => "self.$column" });
    }
    $ns->register_class($moniker => $class);
  }
  # Every connection of the schema works in this test's database, whatever
  # the DSN names.
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

sub group_table { (Group => { table => 'group', columns => \@GROUP_COLUMNS, pk => 'key' }) }
sub order_table {
  my ($columns, %index) = @_;
  return (Order => {
    table => 'order', columns => $columns, pk => 'id',
    unique => { index => [ 'key', 'my-col' ] },
    index  => { rank => [ 'we`ird', 'group' ], %index },
    fk     => [ group => Group => 'key' ],
  });
}
sub select_table {
  my (@fk) = @_;
  return (Select => {
    table => 'select', columns => \@SELECT_COLUMNS, pk => 'id',
    index => { where => ['from'] },
    (@fk ? (fk => \@fk) : ()),
  });
}
# The view's definition is SQL of the schema's author, who quotes in it.
my %DESC_VIEW = (Desc => {
  table => 'desc', view => 'SELECT `key`, `we``ird` FROM `order`',
  columns => [
    key      => { data_type => 'varchar', size => 20, accessor => 'order_key' },
    'we`ird' => { data_type => 'int', is_nullable => 1, accessor => 'weird' },
  ],
});
my %TABLE_TABLE = (Table => {
  table => 'table', columns => \@TABLE_COLUMNS, pk => 'key',
  unique => { unique => [ 'ti`ck', 'order' ] },
  fk     => [ order => Order => 'id' ],
});

# What the server has in this test's database:
#   objects => { name => 'BASE TABLE' or 'VIEW' }
#   columns => { table => [ names in their order ] }
#   keys    => { table => { index => [ 'unique' or 'plain', columns ] } }
#   fks     => { 'table.column' => 'referenced table.column' }
sub server_has {
  my %has = (objects => {}, columns => {}, keys => {}, fks => {});
  $has{objects}{ $_->[0] } = $_->[1] for @{ $raw->selectall_arrayref(
    'SELECT TABLE_NAME, TABLE_TYPE FROM information_schema.TABLES WHERE TABLE_SCHEMA = ?', undef, $DB) };
  push @{ $has{columns}{ $_->[0] } }, $_->[1] for @{ $raw->selectall_arrayref(
    'SELECT TABLE_NAME, COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? '
  . 'ORDER BY TABLE_NAME, ORDINAL_POSITION', undef, $DB) };
  for my $row (@{ $raw->selectall_arrayref(
    'SELECT TABLE_NAME, INDEX_NAME, NON_UNIQUE, COLUMN_NAME FROM information_schema.STATISTICS '
  . 'WHERE TABLE_SCHEMA = ? ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX', undef, $DB) }) {
    my ($table, $name, $non_unique, $column) = @$row;
    $has{keys}{$table}{$name} //= [ $non_unique ? 'plain' : 'unique' ];
    push @{ $has{keys}{$table}{$name} }, $column;
  }
  $has{fks}{"$_->[0].$_->[1]"} = "$_->[2].$_->[3]" for @{ $raw->selectall_arrayref(
    'SELECT TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME '
  . 'FROM information_schema.KEY_COLUMN_USAGE '
  . 'WHERE TABLE_SCHEMA = ? AND REFERENCED_TABLE_NAME IS NOT NULL', undef, $DB) };
  return \%has;
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

# upgrade() of a schema version: the statements it ran, in their order, or
# undef and a diagnostic when it failed. Two things in them are the server's
# and differ between the two products, and neither is a name: MariaDB and
# MySQL before 8.0.17 report an integer type with its display width, and
# MariaDB reports the rule of a foreign key that has none as RESTRICT (in an ADD or in an inline one), which
# the diff then writes out. Both are taken out, so that one list of statements
# stands for both servers.
sub upgrade_to {
  my ($schema, %opts) = @_;
  my $deploy = DBIO::MySQL::Deploy->new(schema => $schema);
  my $diff   = eval { $deploy->upgrade(%opts) };
  if ($@) {
    diag "upgrade failed: $@";
    return;
  }
  return [ map {
    s/\b(int|bigint)\(\d+\)/$1/gr =~ s/ ON UPDATE RESTRICT ON DELETE RESTRICT(?=;\z|\n\))//r
  } $diff ? map { $_->as_sql } @{ $diff->operations } : () ];
}

# Claim 4: the diff of the schema against the database it was just installed
# into or upgraded to has nothing left.
sub nothing_left {
  my ($schema, $name) = @_;
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
  ok $diff && !$diff->has_changes, $name
    or diag $diff ? explain [ map { $_->as_sql } @{ $diff->operations } ] : "the diff failed: $@";
}

# ---------------------------------------------------------------------------
# 1. install
# ---------------------------------------------------------------------------
my $schema = schema_version(group_table(), order_table(\@ORDER_COLUMNS), select_table(), %DESC_VIEW);

unless (ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 },
    'install: the server takes the DDL of a schema named with reserved words, a hyphen and backticks') {
  diag "the install failed, and nothing below can be asked: $@";
  done_testing;
  exit;   # END drops what was created
}

# The keys of `order` as installed. Neither of the schema's indexes starts
# with the column `group`, so the server makes an index of its own for the
# foreign key and names it after the constraint (`order_group_fk`, karr k106).
my %ORDER_KEYS = (
  PRIMARY => [ unique => 'id' ],
  index   => [ unique => 'key', 'my-col' ],
  rank    => [ plain  => 'we`ird', 'group' ],
  order_group_fk => [ plain => 'group' ],
);
my %SELECT_KEYS = (PRIMARY => [ unique => 'id' ], where => [ plain => 'from' ]);

is_deeply server_has(), {
  objects => { group => 'BASE TABLE', order => 'BASE TABLE', select => 'BASE TABLE', desc => 'VIEW' },
  columns => {
    group  => ['key'],
    order  => [ 'id', 'key', 'group', 'my-col', 'we`ird' ],
    select => [ 'id', 'from' ],
    desc   => [ 'key', 'we`ird' ],
  },
  keys => {
    group  => { PRIMARY => [ unique => 'key' ] },
    order  => {%ORDER_KEYS},
    select => {%SELECT_KEYS},
  },
  fks => { 'order.group' => 'group.key' },
}, '... and has every table, column, key, index, foreign key and the view under the name the schema gives it';

nothing_left $schema, '... and the diff against the schema finds nothing left';

# ---------------------------------------------------------------------------
# 2. Rows, through the resultsets
# ---------------------------------------------------------------------------
{
  my $group = eval { $schema->resultset('Group')->create({}) };
  ok $group, 'a row goes into `group`' or diag $@;
  my $order = $group && eval {
    $schema->resultset('Order')->create({
      key => 'first', group => $group->group_key, 'my-col' => 7, 'we`ird' => 9,
    });
  };
  ok $order, '... and one into `order` that references it, every column given' or diag $@;
  my $seen = eval {
    [ map { [ $_->order_key, $_->weird ] } $schema->resultset('Desc')->search({ 'we`ird' => 9 })->all ];
  };
  is_deeply $seen, [ [ first => 9 ] ], '... and comes back through the view `desc`, asked by the column `we`ird`'
    or diag $@;
}

# ---------------------------------------------------------------------------
# 3. upgrade: columns added, a column changed, indexes created, a table
#    created with its primary key, its foreign key and its unique key
# ---------------------------------------------------------------------------
$schema->storage->disconnect;
# `drop` and `select` are NOT NULL without a default: upgrade refuses them for a
# table that holds rows (DBIO::MySQL::Deploy::_refuse_unfillable, karr k120), so
# the rows of section 2 go first.
$raw->do("DELETE FROM `$DB`.`order`");
$raw->do("DELETE FROM `$DB`.`group`");
$schema = schema_version(
  group_table(),
  order_table(\@ORDER_COLUMNS_2, like => ['select'], having => ['my-col']),
  select_table(), %DESC_VIEW, %TABLE_TABLE,
);
# The index `table_order_fk` on `table` is the one the server made for the foreign key
# in the temporary database. The diff writes it, and adds the foreign key after
# it rather than in the CREATE TABLE, where the server would make a second
# index over `order` (karr k92); the constraint has the name the target gives it.
is_deeply upgrade_to($schema), [
  "CREATE TABLE `table` (\n"
    . "  `key` int NOT NULL AUTO_INCREMENT,\n"
    . "  `order` int NOT NULL,\n"
    . "  `ti``ck` int NOT NULL,\n"
    . "  PRIMARY KEY (`key`)\n"
    . ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",
  'ALTER TABLE `order` ADD COLUMN `drop` int NOT NULL;',
  'ALTER TABLE `order` MODIFY COLUMN `my-col` bigint NOT NULL;',
  'ALTER TABLE `order` ADD COLUMN `select` int NOT NULL;',
  'CREATE INDEX `having` ON `order` (`my-col`) USING BTREE;',
  'CREATE INDEX `like` ON `order` (`select`) USING BTREE;',
  'CREATE INDEX `table_order_fk` ON `table` (`order`) USING BTREE;',
  'CREATE UNIQUE INDEX `unique` ON `table` (`ti``ck`, `order`) USING BTREE;',
  'ALTER TABLE `table` ADD CONSTRAINT `table_order_fk` FOREIGN KEY (`order`) REFERENCES `order`(`id`);',
], 'upgrade: a table created, two columns added and one changed, two indexes created, the keys of the new table and its foreign key';

my %TABLE_KEYS = (
  PRIMARY => [ unique => 'key' ],
  unique  => [ unique => 'ti`ck', 'order' ],
  table_order_fk => [ plain => 'order' ],
);
my $has = server_has();
is_deeply $has->{objects},
  { group => 'BASE TABLE', order => 'BASE TABLE', select => 'BASE TABLE', table => 'BASE TABLE', desc => 'VIEW' },
  '... and the server has the new table';
is_deeply $has->{columns},
  {
    group  => ['key'],
    order  => [ 'id', 'key', 'group', 'my-col', 'we`ird', 'drop', 'select' ],
    select => [ 'id', 'from' ],
    desc   => [ 'key', 'we`ird' ],
    table  => [ 'key', 'order', 'ti`ck' ],
  }, '... its columns, and the two new ones of `order`';
is_deeply $has->{keys}, {
  group  => { PRIMARY => [ unique => 'key' ] },
  order  => { %ORDER_KEYS, like => [ plain => 'select' ], having => [ plain => 'my-col' ] },
  select => {%SELECT_KEYS},
  table  => {%TABLE_KEYS},
}, '... its keys, and the two new indexes of `order` beside the ones it had';
is_deeply $has->{fks}, { 'order.group' => 'group.key', 'table.order' => 'order.id' },
  '... and its foreign key beside the one that was there';
is scalar $raw->selectrow_array("SELECT DATA_TYPE FROM information_schema.COLUMNS "
  . "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'order' AND COLUMN_NAME = 'my-col'", undef, $DB),
  'bigint', '... and `my-col` is the wider type';
nothing_left $schema, '... and the next diff has nothing left';

# ---------------------------------------------------------------------------
# 4. upgrade: a column dropped, an index dropped, a foreign key added
# ---------------------------------------------------------------------------
$schema->storage->disconnect;
$schema = schema_version(
  group_table(),
  order_table(\@ORDER_COLUMNS_3, like => ['select']),
  select_table(from => Group => 'key'), %DESC_VIEW, %TABLE_TABLE,
);
# The constraint has the name the server gave it in the temporary database.
is_deeply upgrade_to($schema, allow_destructive => 1), [
  'DROP INDEX `having` ON `order`;',
  'ALTER TABLE `order` DROP COLUMN `drop`;',
  'ALTER TABLE `select` ADD CONSTRAINT `select_from_fk` FOREIGN KEY (`from`) REFERENCES `group`(`key`);',
], 'upgrade: a column dropped, an index dropped, a foreign key added to a table that is there';

$has = server_has();
is_deeply $has->{columns}{order}, [ 'id', 'key', 'group', 'my-col', 'we`ird', 'select' ],
  '... and the server no longer has the column';
is_deeply $has->{keys}{order}, { %ORDER_KEYS, like => [ plain => 'select' ] },
  '... nor the index, while the others are still there';
is_deeply $has->{fks},
  { 'order.group' => 'group.key', 'table.order' => 'order.id', 'select.from' => 'group.key' },
  '... and has the foreign key';
nothing_left $schema, '... and the next diff has nothing left';

# ---------------------------------------------------------------------------
# 5. upgrade: a foreign key dropped and added again, a table dropped
# ---------------------------------------------------------------------------
$schema->storage->disconnect;
$schema = schema_version(
  group_table(),
  order_table(\@ORDER_COLUMNS_3, like => ['select']),
  select_table(from => Order => 'id'), %DESC_VIEW,
);
# The constraint that leaves is dropped before the table (karr k94).
is_deeply upgrade_to($schema, allow_destructive => 1), [
  'ALTER TABLE `select` DROP FOREIGN KEY `select_from_fk`;',
  'DROP TABLE `table`;',
  'ALTER TABLE `select` ADD CONSTRAINT `select_from_fk` FOREIGN KEY (`from`) REFERENCES `order`(`id`);',
], 'upgrade: a table dropped, and a foreign key that references another table now dropped and added again';

$has = server_has();
is_deeply $has->{objects},
  { group => 'BASE TABLE', order => 'BASE TABLE', select => 'BASE TABLE', desc => 'VIEW' },
  '... and the server no longer has the table';
is_deeply $has->{fks}, { 'order.group' => 'group.key', 'select.from' => 'order.id' },
  '... and the foreign key references the other table';
nothing_left $schema, '... and the next diff has nothing left';

note 'warned during the run: ' . join ' | ', map { s/\s+\z//r } @warnings if @warnings;

$schema->storage->disconnect;
drop_database();
$raw->disconnect;
undef $raw;

done_testing;
