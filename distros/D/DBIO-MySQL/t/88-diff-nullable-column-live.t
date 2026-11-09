use strict;
use warnings;
use Test::More;

# LIVE half of karr k87: DBIO::MySQL::Deploy->upgrade adds and changes a column
# that is nullable and has no default.
#
# WHY IT MATTERS. That is the plainest column there is, and an upgrade could
# not write it on MariaDB. MariaDB reports the keyword NULL as COLUMN_DEFAULT
# of such a column -- a text of four letters, where MySQL reports SQL NULL --
# and the introspection handed it on as the default 'NULL' (t/44 has the
# offline half and what each server reports). So the statement for a nullable
# column an upgrade added, changed or created a table with ended in
# DEFAULT 'NULL': for a number the server refused it (1067) and the upgrade
# ended there; for a string it ran, and the column from then on defaulted to
# the word NULL instead of to nothing.
#
# What this file claims, through upgrade() of a schema against a database that
# has an earlier version of it and rows in the table:
#   1. the introspection reads the installed table as it is: no default for
#      the nullable columns, and a default for the column that has the string
#      NULL as its default -- the same four letters, and not the same thing;
#   2. an upgrade adds a nullable number and a nullable string, changes the
#      type of a nullable number, and creates a table with a nullable number,
#      in the statements this file names, none of which has a DEFAULT;
#   3. a second upgrade changes the type of the column the first one added;
#   4. after each, the server has those columns nullable and without a
#      default: a row that does not name them gets NULL in each -- NULL, and
#      not the word -- and the rows that were there have what they had;
#   5. the column whose default is the string NULL still has it;
#   6. after install and after each upgrade the next diff has nothing left.
#
# NOT claimed, and the schema is built to stay clear of it:
#   - what a diff writes for a default that is there (karr k78): the one
#     column with a default is created by install and no upgrade touches it;
#   - text columns of a table an upgrade creates (karr k82): the one created
#     here has numbers only;
#   - indexes and foreign keys: there are none beside the primary keys.
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
use DBIO::MySQL::Introspect;

my $DB = "dbio_k87_$$";

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
# One version of the schema, connected to the database of this test:
#   Moniker => [ column => \%info, ... ]   # beside the primary key `id`
# The table is named after the moniker, in lowercase.
my $version = 0;
sub schema_version {
  my (%sources) = @_;
  my $ns = 'K87Live::V' . ++$version;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $moniker (sort keys %sources) {
    my $class = "${ns}::Result::$moniker";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table(lc $moniker);
    $class->add_columns(id => { data_type => 'int', is_auto_increment => 1 }, @{ $sources{$moniker} });
    $class->set_primary_key('id');
    $ns->register_class($moniker => $class);
  }
  # Every connection of the schema works in this test's database, whatever
  # the DSN names.
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

my @NULLABLE = (is_nullable => 1);

# `item` as install creates it: a number that has to be there, a nullable
# number, and a string whose default is the word NULL.
my @ITEM_1 = (
  qty  => { data_type => 'int' },
  note => { data_type => 'int', @NULLABLE },
  code => { data_type => 'varchar', size => 20, default_value => 'NULL' },
);
# ... after the first upgrade: `note` wider, and two nullable columns more,
# beside a table `part` that is new.
my @ITEM_2 = (
  qty    => { data_type => 'int' },
  note   => { data_type => 'bigint', @NULLABLE },
  code   => { data_type => 'varchar', size => 20, default_value => 'NULL' },
  amount => { data_type => 'int', @NULLABLE },
  label  => { data_type => 'varchar', size => 20, @NULLABLE },
);
my @PART = (
  weight => { data_type => 'int', @NULLABLE },
);
# ... and after the second: `amount`, which the first one added, wider.
my @ITEM_3 = @ITEM_2;
$ITEM_3[7] = { data_type => 'bigint', @NULLABLE };

# What the server says of a table, column by column in their order:
# [ name, 'null' or 'not null' ].
sub server_columns {
  my ($table) = @_;
  return [ map { [ $_->[0], $_->[1] eq 'YES' ? 'null' : 'not null' ] } @{ $raw->selectall_arrayref(
    'SELECT COLUMN_NAME, IS_NULLABLE FROM information_schema.COLUMNS '
  . 'WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? ORDER BY ORDINAL_POSITION', undef, $DB, $table) } ];
}

# What the introspection makes of the columns of a table: name => default.
sub read_defaults {
  $raw->do("USE `$DB`");
  my $columns = DBIO::MySQL::Introspect->new(dbh => $raw)->model->{columns}{ $_[0] };
  return { map { $_->{column_name} => $_->{default_value} } @$columns };
}

# The rows of a table, in the columns named, by `id` -- or what the server
# said instead, where an upgrade did not get as far as those columns.
sub rows {
  my ($table, @columns) = @_;
  return eval { $raw->selectall_arrayref(
    'SELECT ' . join(', ', map { "`$_`" } @columns) . " FROM `$DB`.`$table` ORDER BY `id`") }
    // "the server has no such rows: $@";
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

# upgrade() of a schema version: the statements it ran, in their order, or
# undef and a diagnostic when it failed. MariaDB and MySQL before 8.0.17 report
# an integer type with its display width, which is taken out, so that one list
# of statements stands for both servers.
sub upgrade_to {
  my ($schema) = @_;
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade };
  if ($@) {
    diag "upgrade failed: $@";
    return;
  }
  return [ map { s/\b(int|bigint)\(\d+\)/$1/gr } $diff ? map { $_->as_sql } @{ $diff->operations } : () ];
}

sub nothing_left {
  my ($schema, $name) = @_;
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
  ok $diff && !$diff->has_changes, $name
    or diag $diff ? explain [ map { $_->as_sql } @{ $diff->operations } ] : "the diff failed: $@";
}

# ---------------------------------------------------------------------------
# install: the table the upgrades start from
# ---------------------------------------------------------------------------
my $schema = schema_version(Item => \@ITEM_1);

unless (ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'the first version installs') {
  diag "the install failed, and nothing below can be asked: $@";
  done_testing;
  exit;   # END drops what was created
}

$raw->do("INSERT INTO `$DB`.`item` (`qty`, `note`) VALUES (1, 7), (2, NULL)");

is_deeply server_columns('item'),
  [ [ id => 'not null' ], [ qty => 'not null' ], [ note => 'null' ], [ code => 'not null' ] ],
  '... and the server has its columns, `note` nullable';

{
  my $defaults = read_defaults('item');
  is $defaults->{note}, undef, 'the introspection reads no default for the nullable number';
  is $defaults->{qty},  undef, '... and none for the number that has to be there';
  like $defaults->{code}, qr/\A'?NULL'?\z/,
    '... and one for the string whose default is the word NULL';
}

nothing_left $schema, '... and the next diff has nothing left';
$schema->storage->disconnect;

# ---------------------------------------------------------------------------
# first upgrade: nullable columns added, changed, and in a table that is new
# ---------------------------------------------------------------------------
$schema = schema_version(Item => \@ITEM_2, Part => \@PART);

is_deeply scalar upgrade_to($schema), [
  "CREATE TABLE `part` (\n"
    . "  `id` int NOT NULL AUTO_INCREMENT,\n"
    . "  `weight` int,\n"
    . "  PRIMARY KEY (`id`)\n"
    . ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",
  'ALTER TABLE `item` ADD COLUMN `amount` int;',
  'ALTER TABLE `item` ADD COLUMN `label` varchar(20);',
  'ALTER TABLE `item` MODIFY COLUMN `note` bigint;',
], 'upgrade adds, changes and creates the nullable columns, in statements without a DEFAULT';

is_deeply server_columns('item'), [
  [ id => 'not null' ], [ qty => 'not null' ], [ note => 'null' ], [ code => 'not null' ],
  [ amount => 'null' ], [ label => 'null' ],
], '... and the server has the columns of `item`, the new ones nullable and `note` still';
is_deeply server_columns('part'), [ [ id => 'not null' ], [ weight => 'null' ] ],
  '... and those of `part`';

# A row that names none of the nullable columns, and one in the new table.
ok eval {
  $raw->do("INSERT INTO `$DB`.`item` (`qty`) VALUES (3)");
  $raw->do("INSERT INTO `$DB`.`part` () VALUES ()");
  1;
}, '... and takes a row that names none of them' or diag $@;

is_deeply rows(item => qw(qty note code amount label)), [
  [ 1, 7,     'NULL', undef, undef ],
  [ 2, undef, 'NULL', undef, undef ],
  [ 3, undef, 'NULL', undef, undef ],
], '... every nullable column of it NULL and not the word, the rows from before as they were, '
 . 'and `code` still defaulting to the word';
is_deeply rows(part => 'weight'), [ [undef] ], '... and NULL in the new table too';

{
  my $defaults = read_defaults('item');
  my $code     = delete $defaults->{code};
  is_deeply $defaults, { id => undef, qty => undef, note => undef, amount => undef, label => undef },
    '... and the introspection reads no default for any column but `code`';
  like $code, qr/\A'?NULL'?\z/, '... which still has its own';
}

nothing_left $schema, '... and the next diff has nothing left';
$schema->storage->disconnect;

# ---------------------------------------------------------------------------
# second upgrade: the column the first one added gets another type
# ---------------------------------------------------------------------------
ok eval { $raw->do("UPDATE `$DB`.`item` SET `amount` = 40 WHERE `qty` = 1"); 1 },
  'a row gets a number in the column the first upgrade added' or diag $@;

$schema = schema_version(Item => \@ITEM_3, Part => \@PART);

is_deeply scalar upgrade_to($schema), [ 'ALTER TABLE `item` MODIFY COLUMN `amount` bigint;' ],
  'upgrade changes the nullable column the upgrade before added';

is_deeply server_columns('item'), [
  [ id => 'not null' ], [ qty => 'not null' ], [ note => 'null' ], [ code => 'not null' ],
  [ amount => 'null' ], [ label => 'null' ],
], '... and it is still nullable';

ok eval { $raw->do("INSERT INTO `$DB`.`item` (`qty`) VALUES (4)"); 1 },
  '... and the table takes a row that does not name it' or diag $@;
is_deeply rows(item => qw(qty note amount label)), [
  [ 1, 7,     40,    undef ],
  [ 2, undef, undef, undef ],
  [ 3, undef, undef, undef ],
  [ 4, undef, undef, undef ],
], '... which gets NULL there, beside the rows from before as they were';

nothing_left $schema, '... and the next diff has nothing left';
$schema->storage->disconnect;

note 'warned during the run: ' . join ' | ', map { s/\s+\z//r } @warnings if @warnings;

drop_database();
$raw->disconnect;
undef $raw;

done_testing;
