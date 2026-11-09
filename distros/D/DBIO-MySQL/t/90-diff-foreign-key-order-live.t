use strict;
use warnings;
use Test::More;

# LIVE half of karr k94 and karr k81: where the foreign key statements and the
# index statements of one upgrade() stand against each other.
#
# WHY IT MATTERS. The server checks a foreign key against the indexes at the
# moment of each statement, so one upgrade() that is right in what it changes
# and wrong in what comes first stops half way: the foreign key and the index
# it needed stay, and the next upgrade() meets the same wall. What the servers
# take, only they can say, and MySQL and MariaDB each say it for themselves.
#
# What this file claims, each time through upgrade() of a schema against a
# database that has the earlier version of it installed:
#   k94 A. a foreign key leaves the schema, and the schema has no index of its
#          own over the referencing column (the normal case of belongs_to):
#          the server's index over the column goes after the constraint;
#   k94 B. the referenced table and the referencing one both leave the schema:
#          the constraint is dropped first, the tables after;
#   k94 C. the referenced table leaves, the referencing one stays without the
#          foreign key;
#   k81 1. a parent and a child that references a unique key of it are both new:
#          the unique key is there before the foreign key;
#   k81 2. the unique key a foreign key needs is extended to another set of
#          columns, under its name and under another one: the foreign key gets
#          an index at every statement, and still has one afterwards;
#   k92.   a new table references the primary key of a table that is there:
#          the index over its column is created before the foreign key, and
#          the server has that one index over the column, not two.
# Each time the statements are the ones named here, in this order, the server
# has what the schema names and no more, a row the foreign key must refuse is
# refused (where it stays), and the next diff has nothing left to say.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in a database of its own, created and dropped here (see t/86, t/105).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use DiffTempDbProbe qw(temp_db_skip_reason);

my $DB = "dbio_k94_$$";

my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
my ($dbd) = $dsn =~ /\Adbi:(\w+):/;

sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
sub fresh_database { drop_database(); $raw->do("CREATE DATABASE `$DB`"); $raw->do("USE `$DB`") }
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
# The schema
# ---------------------------------------------------------------------------
#   Moniker => { table => ..., columns => [ names, all integers, id first ],
#                unique => { name => [columns] },
#                fk     => [ column => Moniker => its column ] }   # belongs_to
# A moniker sorts after the one it references (install_ddl writes the tables
# in that order, karr k84): A_ is the referenced one, B_ the referencing one.
my $version = 0;
sub schema_version {
  my (%sources) = @_;
  my $ns = 'K94Live::V' . ++$version;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $moniker (sort keys %sources) {
    my $def   = $sources{$moniker};
    my $class = "${ns}::Result::$moniker";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table($def->{table});
    my ($id, @others) = @{ $def->{columns} };
    $class->add_columns(
      $id => { data_type => 'integer', is_auto_increment => 1 },
      # `extra` is added to a table that holds rows: a default, or upgrade refuses it
      # (DBIO::MySQL::Deploy::_refuse_unfillable, karr k120)
      map { $_ => { data_type => 'integer', ($_ eq 'extra' ? (default_value => 0) : ()) } } @others,
    );
    $class->set_primary_key($id);
    $class->add_unique_constraint($_ => $def->{unique}{$_}) for sort keys %{ $def->{unique} // {} };
    if (my $fk = $def->{fk}) {
      my ($column, $to, $to_column) = @$fk;
      $class->belongs_to("rel_$to" => "${ns}::Result::$to", { "foreign.$to_column" => "self.$column" });
    }
    $ns->register_class($moniker => $class);
  }
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

# 'table.column' => 'referenced table.column'
sub server_fks {
  return { map { ("$_->[0].$_->[1]" => "$_->[2].$_->[3]") } @{ $raw->selectall_arrayref(
    'SELECT TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME '
  . 'FROM information_schema.KEY_COLUMN_USAGE '
  . 'WHERE TABLE_SCHEMA = ? AND REFERENCED_TABLE_NAME IS NOT NULL', undef, $DB) } };
}
sub server_tables {
  return $raw->selectcol_arrayref(
    'SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? ORDER BY TABLE_NAME', undef, $DB);
}
# name => [ unique|plain, columns in their order ], the primary key left out.
sub server_keys {
  my ($table) = @_;
  my %got;
  for my $row (@{ $raw->selectall_arrayref(
    'SELECT INDEX_NAME, NON_UNIQUE, COLUMN_NAME FROM information_schema.STATISTICS '
  . 'WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? ORDER BY INDEX_NAME, SEQ_IN_INDEX', undef, $DB, $table,
  ) }) {
    my ($name, $non_unique, $column) = @$row;
    next if $name eq 'PRIMARY';
    $got{$name} //= [ $non_unique ? 'plain' : 'unique' ];
    push @{ $got{$name} }, $column;
  }
  return \%got;
}

sub is_refused {
  my ($sql, @bind) = @_;
  my $went_in = eval { $raw->do($sql, undef, @bind); 1 };
  my $error   = "$@";
  return !$went_in && $error =~ /foreign key constraint fails/ ? 1 : 0;
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

sub upgrade_to {
  my ($schema, %opts) = @_;
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade(%opts) };
  if ($@) {
    diag "upgrade failed: $@";
    return;
  }
  return [ $diff ? map { $_->as_sql } @{ $diff->operations } : () ];
}

sub nothing_left {
  my ($schema, $name) = @_;
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
  ok $diff && !$diff->has_changes, $name
    or diag $diff ? explain [ map { $_->as_sql } @{ $diff->operations } ] : "the diff failed: $@";
}

# The statements with the layout of CREATE TABLE, the display width of the
# integers and the RESTRICT that MariaDB reports for what MySQL reports as
# NO ACTION (the same behaviour, and not written for the latter) taken out, so
# that one list stands for both servers.
sub flat {
  return [ map { s/\s+/ /gr =~ s/\b(int|bigint)\(\d+\)/$1/gr =~ s/ ON (?:UPDATE|DELETE) RESTRICT//gr } @{ $_[0] } ];
}

# Install a version of the schema into a fresh database, hand it back.
sub installed {
  my (%sources) = @_;
  fresh_database();
  my $schema = schema_version(%sources);
  ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'the earlier schema installs'
    or diag "the install failed: $@";
  return $schema;
}

my %OTHER = (Z_Other => { table => 'other', columns => ['id'] });

# ---------------------------------------------------------------------------
# k94
# ---------------------------------------------------------------------------
my %AUTHOR = (A_Author => { table => 'author', columns => ['id'] });
sub book { return (B_Book => { table => 'book', columns => [ 'id', 'author_id' ],
  (@_ ? (fk => [ @_ ]) : ()) }) }

subtest 'k94 A: a foreign key leaves, the server\'s index over its column with it' => sub {
  my $schema = installed(%AUTHOR, book(author_id => A_Author => 'id'), %OTHER);
  is_deeply server_fks(), { 'book.author_id' => 'author.id' }, '... the foreign key is there';
  is_deeply server_keys('book'), { book_author_id_fk => [ plain => 'author_id' ] },
    '... and the server made an index for it, which the schema does not have';
  $raw->do('INSERT INTO `author` (`id`) VALUES (1)');
  ok is_refused('INSERT INTO `book` (`author_id`) VALUES (?)', 999), '... and it refuses a book of no author';
  $schema->storage->disconnect;

  $schema = schema_version(%AUTHOR, book(), %OTHER);
  is_deeply flat(upgrade_to($schema, allow_destructive => 1)), [
    'ALTER TABLE `book` DROP FOREIGN KEY `book_author_id_fk`;',
    'DROP INDEX `book_author_id_fk` ON `book`;',
  ], 'upgrade drops the foreign key, then the index it needed';
  is_deeply server_fks(), {}, '... the server has no foreign key';
  is_deeply server_keys('book'), {}, '... and no index over the column';
  ok eval { $raw->do('INSERT INTO `book` (`author_id`) VALUES (?)', undef, 999); 1 }, '... and takes the row it refused'
    or diag $@;
  nothing_left $schema, '... and the next diff has nothing left';
  $schema->storage->disconnect;
};

subtest 'k94 B: the referenced table and the referencing one both leave' => sub {
  my $schema = installed(%AUTHOR, book(author_id => A_Author => 'id'), %OTHER);
  $schema->storage->disconnect;

  $schema = schema_version(%OTHER);
  is_deeply flat(upgrade_to($schema, allow_destructive => 1)), [
    'ALTER TABLE `book` DROP FOREIGN KEY `book_author_id_fk`;',
    'DROP TABLE `author`;',
    'DROP TABLE `book`;',
  ], 'upgrade drops the constraint, then the two tables';
  is_deeply server_tables(), ['other'], '... and the server has the table of the schema and no other';
  nothing_left $schema, '... and the next diff has nothing left';
  $schema->storage->disconnect;
};

subtest 'k94 C: the referenced table leaves, the referencing one stays without the foreign key' => sub {
  my $schema = installed(%AUTHOR, book(author_id => A_Author => 'id'), %OTHER);
  $schema->storage->disconnect;

  $schema = schema_version(book(), %OTHER);
  is_deeply flat(upgrade_to($schema, allow_destructive => 1)), [
    'ALTER TABLE `book` DROP FOREIGN KEY `book_author_id_fk`;',
    'DROP TABLE `author`;',
    'DROP INDEX `book_author_id_fk` ON `book`;',
  ], 'upgrade drops the constraint, the table, and then the index the constraint needed';
  is_deeply server_tables(), [qw(book other)], '... and the server has the tables of the schema and no other';
  is_deeply server_fks(), {}, '... no foreign key';
  is_deeply server_keys('book'), {}, '... and no index over the column';
  nothing_left $schema, '... and the next diff has nothing left';
  $schema->storage->disconnect;
};

# ---------------------------------------------------------------------------
# k81
# ---------------------------------------------------------------------------
sub parent {
  my (%unique) = @_;
  return (A_Parent => { table => 'a_parent', columns => [ 'id', 'code', 'region' ], unique => {%unique} });
}
sub parent_with {
  my ($extra, %unique) = @_;
  return (A_Parent => { table => 'a_parent', columns => [ 'id', 'code', 'region', $extra ], unique => {%unique} });
}
sub child { return (B_Child => { table => 'b_child', columns => [ 'id', 'parent_code' ],
  fk => [ parent_code => A_Parent => 'code' ] }) }

subtest 'k81 1: parent and child are new, the foreign key is to a unique key of the parent' => sub {
  fresh_database();
  my $first = schema_version(%OTHER);
  DBIO::MySQL::Deploy->new(schema => $first)->install;
  $first->storage->disconnect;

  my $schema = schema_version(parent(uniq_parent_code => ['code']), child(), %OTHER);
  is_deeply flat(upgrade_to($schema)), [
    'CREATE TABLE `a_parent` ( `id` bigint NOT NULL AUTO_INCREMENT, `code` bigint NOT NULL, `region` bigint NOT NULL, PRIMARY KEY (`id`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;',
    'CREATE TABLE `b_child` ( `id` bigint NOT NULL AUTO_INCREMENT, `parent_code` bigint NOT NULL, PRIMARY KEY (`id`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;',
    'CREATE UNIQUE INDEX `uniq_parent_code` ON `a_parent` (`code`) USING BTREE;',
    'CREATE INDEX `b_child_parent_code_fk` ON `b_child` (`parent_code`) USING BTREE;',
    'ALTER TABLE `b_child` ADD CONSTRAINT `b_child_parent_code_fk` FOREIGN KEY (`parent_code`) REFERENCES `a_parent`(`code`);',
  ], 'upgrade creates the tables, the keys, and then the foreign key (not in the CREATE TABLE)';
  is_deeply server_fks(), { 'b_child.parent_code' => 'a_parent.code' }, '... the server has the foreign key';
  is_deeply server_keys('a_parent'), { uniq_parent_code => [ unique => 'code' ] }, '... and the unique key';
  $raw->do('INSERT INTO `a_parent` (`code`, `region`) VALUES (7, 1)');
  ok is_refused('INSERT INTO `b_child` (`parent_code`) VALUES (?)', 999), '... and it refuses a child of no parent';
  nothing_left $schema, '... and the next diff has nothing left';
  $schema->storage->disconnect;
};

for my $case (
  [ 'under its name', 'uniq_parent_code', [
      'ALTER TABLE `a_parent` DROP INDEX `uniq_parent_code`, ADD UNIQUE INDEX `uniq_parent_code` (`code`, `region`) USING BTREE;',
  ] ],
  [ 'under another name', 'uniq_parent_pair', [
      'CREATE UNIQUE INDEX `uniq_parent_pair` ON `a_parent` (`code`, `region`) USING BTREE;',
      'DROP INDEX `uniq_parent_code` ON `a_parent`;',
  ] ],
) {
  my ($label, $to_name, $ran) = @$case;
  subtest "k81 2: the unique key the foreign key needs is extended, $label" => sub {
    my $schema = installed(parent(uniq_parent_code => ['code']), child(), %OTHER);
    $raw->do('INSERT INTO `a_parent` (`code`, `region`) VALUES (7, 1)');
    $raw->do('INSERT INTO `b_child` (`parent_code`) VALUES (7)');
    $schema->storage->disconnect;

    $schema = schema_version(parent($to_name => [ 'code', 'region' ]), child(), %OTHER);
    is_deeply flat(upgrade_to($schema, allow_destructive => (grep { /^DROP INDEX/ } @$ran) ? 1 : 0)), $ran, 'upgrade runs: ' . join ' ', @$ran;
    is_deeply server_fks(), { 'b_child.parent_code' => 'a_parent.code' }, '... the foreign key is still there';
    is_deeply server_keys('a_parent'), { $to_name => [ unique => 'code', 'region' ] },
      '... over the parent the key of the schema and no other';
    ok is_refused('INSERT INTO `b_child` (`parent_code`) VALUES (?)', 999), '... and it still refuses a child of no parent';
    nothing_left $schema, '... and the next diff has nothing left';
    $schema->storage->disconnect;
  };
}

# The replacement is over a column the schema adds in the same upgrade: the
# column comes first, then the replacement, and the old key goes after it.
for my $case (
  [ 'under its name', 'uniq_parent_code', [
      'ALTER TABLE `a_parent` ADD COLUMN `extra` bigint NOT NULL DEFAULT \'0\';',
      'ALTER TABLE `a_parent` DROP INDEX `uniq_parent_code`, ADD UNIQUE INDEX `uniq_parent_code` (`code`, `extra`) USING BTREE;',
  ] ],
  [ 'under another name', 'uniq_parent_triple', [
      'ALTER TABLE `a_parent` ADD COLUMN `extra` bigint NOT NULL DEFAULT \'0\';',
      'CREATE UNIQUE INDEX `uniq_parent_triple` ON `a_parent` (`code`, `extra`) USING BTREE;',
      'DROP INDEX `uniq_parent_code` ON `a_parent`;',
  ] ],
) {
  my ($label, $to_name, $ran) = @$case;
  subtest "k81 2: ... over a column that is new, $label" => sub {
    my $schema = installed(parent(uniq_parent_code => ['code']), child(), %OTHER);
    $raw->do('INSERT INTO `a_parent` (`code`, `region`) VALUES (7, 1)');
    $raw->do('INSERT INTO `b_child` (`parent_code`) VALUES (7)');
    $schema->storage->disconnect;

    $schema = schema_version(parent_with(extra => $to_name => [ 'code', 'extra' ]), child(), %OTHER);
    is_deeply flat(upgrade_to($schema, allow_destructive => (grep { /^DROP INDEX/ } @$ran) ? 1 : 0)), $ran, 'upgrade runs: ' . join ' ', @$ran;
    is_deeply server_fks(), { 'b_child.parent_code' => 'a_parent.code' }, '... the foreign key is still there';
    is_deeply server_keys('a_parent'), { $to_name => [ unique => 'code', 'extra' ] },
      '... over the parent the key of the schema and no other';
    ok is_refused('INSERT INTO `b_child` (`parent_code`) VALUES (?)', 999), '... and it still refuses a child of no parent';
    nothing_left $schema, '... and the next diff has nothing left';
    $schema->storage->disconnect;
  };
}

# A new table that references the primary key of an existing one (karr k92).
# The target has the index the server made for the foreign key in the
# temporary database, and the diff creates it; in the CREATE TABLE the server
# would make one of its own, and the CREATE INDEX a second one over the same
# column. So the foreign key is added after the index, and the server keeps the
# one index.
subtest 'k92: a new table references the primary key: the index over its column first, then the foreign key' => sub {
  my $schema = installed(%AUTHOR, %OTHER);
  $schema->storage->disconnect;
  $schema = schema_version(%AUTHOR, book(author_id => A_Author => 'id'), %OTHER);
  is_deeply flat(upgrade_to($schema)), [
    'CREATE TABLE `book` ( `id` bigint NOT NULL AUTO_INCREMENT, `author_id` bigint NOT NULL, PRIMARY KEY (`id`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;',
    'CREATE INDEX `book_author_id_fk` ON `book` (`author_id`) USING BTREE;',
    'ALTER TABLE `book` ADD CONSTRAINT `book_author_id_fk` FOREIGN KEY (`author_id`) REFERENCES `author`(`id`);',
  ], 'upgrade creates the table without the foreign key, the index, and then the foreign key';
  is_deeply server_fks(), { 'book.author_id' => 'author.id' }, '... the server has the foreign key';
  is_deeply server_keys('book'), { book_author_id_fk => [ plain => 'author_id' ] },
    '... and one index over its column, the one of the diff';
  nothing_left $schema, '... and the next diff has nothing left';
  $schema->storage->disconnect;
};

note 'warned during the run: ' . join ' | ', map { s/\s+\z//r } @warnings if @warnings;

drop_database();
$raw->disconnect;
undef $raw;

done_testing;
