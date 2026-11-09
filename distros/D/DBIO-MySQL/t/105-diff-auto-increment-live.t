use strict;
use warnings;
use Test::More;

# LIVE half of karr k80 and karr k93: DBIO::MySQL::Deploy->upgrade and a column
# that is AUTO_INCREMENT.
#
# WHY IT MATTERS. Two things went wrong with such a column, and the diff
# could not see either.
#   - MODIFY COLUMN restates the column, and the statement the diff wrote left
#     AUTO_INCREMENT out: an upgrade that changed the type of an AUTO_INCREMENT
#     primary key took the attribute away, and the next INSERT without an id
#     failed ("Field 'id' doesn't have a default value"). And AUTO_INCREMENT
#     that a schema gained or lost was no change to the diff at all (k93).
#   - An AUTO_INCREMENT column that is not the primary key has to have a key,
#     and both servers refuse the DROP INDEX of its only one (1075) -- when
#     the column loses the attribute and the key, and when the column leaves
#     the schema with its key, because the DROP COLUMN comes after. The server
#     accepts the column without AUTO_INCREMENT first, the DROP INDEX then,
#     and everything else after (k80).
# What the servers take, only they can say, and MySQL and MariaDB each say it
# for themselves.
#
# What this file claims, each time through upgrade() against a database that
# has the earlier version of the schema installed and rows in the table, and
# for a unique key and a plain index alike:
#   A. `seq`, AUTO_INCREMENT and not the primary key, loses the attribute and
#      its only key;
#   B. the same, and the column changes its type (int to bigint) at once;
#   C. `seq` leaves the schema with its key.
# Upgrade then runs the MODIFY without AUTO_INCREMENT, the DROP INDEX, and the
# rest, in that order; the server has the columns the schema names and no key;
# the rows are still there; and the next diff has nothing left to say.
# And, for the primary key:
#   D. an AUTO_INCREMENT primary key changes its type (int to bigint): the
#      column is AUTO_INCREMENT afterwards, an INSERT without an id gets one,
#      and the next diff has nothing left to say.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in a database of its own, created and dropped here (see t/87).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use DiffTempDbProbe qw(temp_db_skip_reason);

my $DB = "dbio_k93_$$";

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
# The schema: one table `item`, in the two versions of a case
# ---------------------------------------------------------------------------
#   pk      => 'int' | 'bigint'        # the type of the AUTO_INCREMENT `id`
#                                      # (D); otherwise `id` is a plain int
#   seq     => 'auto' | 'int' | 'bigint' | undef   # the column `seq`
#   kind    => 'unique'                # the key `k_item` over `seq`, when `seq`
#                                      # is 'auto'
my $version = 0;
sub schema_version {
  my (%def) = @_;
  my $ns    = 'K93Live::V' . ++$version;
  my $class = "${ns}::Result::Item";
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
  $class->table('item');
  my $seq = $def{seq};
  $class->add_columns(
    id => $def{pk} ? { data_type => $def{pk}, is_auto_increment => 1 } : { data_type => 'int' },
    ($seq
      ? (seq => $seq eq 'auto' ? { data_type => 'int', is_auto_increment => 1 } : { data_type => $seq })
      : ()),
    note => { data_type => 'int' },
  );
  $class->set_primary_key('id');
  if ($seq && $seq eq 'auto') {
    $def{kind} eq 'unique'
      ? $class->add_unique_constraint(k_item => ['seq'])
      : $class->mysql_index(k_item => { columns => ['seq'] });
  }
  $ns->register_class(Item => $class);
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

sub server_columns {
  return $raw->selectcol_arrayref(
    'SELECT COLUMN_NAME FROM information_schema.COLUMNS '
  . "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'item' ORDER BY ORDINAL_POSITION", undef, $DB);
}
sub server_keys {
  my %got;
  for my $row (@{ $raw->selectall_arrayref(
    'SELECT INDEX_NAME, NON_UNIQUE, COLUMN_NAME FROM information_schema.STATISTICS '
  . "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'item' ORDER BY INDEX_NAME, SEQ_IN_INDEX", undef, $DB,
  ) }) {
    my ($name, $non_unique, $column) = @$row;
    next if $name eq 'PRIMARY';
    $got{$name} //= [ $non_unique ? 'plain' : 'unique' ];
    push @{ $got{$name} }, $column;
  }
  return \%got;
}
# The type of a column as the server has it, without a display width.
sub server_type {
  my ($column) = @_;
  my ($t) = $raw->selectrow_array(
    'SELECT COLUMN_TYPE FROM information_schema.COLUMNS '
  . "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'item' AND COLUMN_NAME = ?", undef, $DB, $column);
  return $t =~ s/\(\d+\)//r;
}
sub server_extra {
  my ($column) = @_;
  return scalar $raw->selectrow_array(
    'SELECT EXTRA FROM information_schema.COLUMNS '
  . "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'item' AND COLUMN_NAME = ?", undef, $DB, $column);
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

# upgrade() of a schema version: the statements it ran, in their order, or
# undef and a diagnostic when it failed. MariaDB and MySQL before 8.0.17 report
# an integer type with its display width, which is taken out, so that one list
# of statements stands for both servers.
sub upgrade_to {
  my ($schema, %opts) = @_;
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade(%opts) };
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
# The cases
# ---------------------------------------------------------------------------
my $DROP_KEY = 'DROP INDEX `k_item` ON `item`;';

# `seq` is the AUTO_INCREMENT column, `note` another, and `id` the primary key.
my @CASES = (
  {
    name => 'A: the column loses AUTO_INCREMENT and its only key',
    from => { seq => 'auto' },
    to   => { seq => 'int' },
    ran  => [ 'ALTER TABLE `item` MODIFY COLUMN `seq` int NOT NULL;', $DROP_KEY ],
    columns => [qw(id seq note)], type => { seq => 'int' },
  },
  {
    name => 'B: ... and changes its type at the same time',
    from => { seq => 'auto' },
    to   => { seq => 'bigint' },
    ran  => [ 'ALTER TABLE `item` MODIFY COLUMN `seq` bigint NOT NULL;', $DROP_KEY ],
    columns => [qw(id seq note)], type => { seq => 'bigint' },
  },
  {
    name => 'C: the column leaves the schema with its key',
    from => { seq => 'auto' },
    to   => {},
    ran  => [
      'ALTER TABLE `item` MODIFY COLUMN `seq` int NOT NULL;',
      $DROP_KEY,
      'ALTER TABLE `item` DROP COLUMN `seq`;',
    ],
    columns => [qw(id note)], type => {},
  },
);

for my $kind (qw(unique)) {
  for my $case (@CASES) {
    subtest "$kind key, $case->{name}" => sub {
      my @ran = @{ $case->{ran} };
      drop_database();
      $raw->do("CREATE DATABASE `$DB`");

      my $schema = schema_version(%{ $case->{from} }, kind => $kind);
      unless (ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'the earlier schema installs') {
        diag "the install failed, and nothing of this case can be asked: $@";
        $schema->storage->disconnect;
        return;
      }
      $raw->do("INSERT INTO `$DB`.`item` (`id`, `note`) VALUES (?, ?)", undef, $_, $_ * 10) for 1 .. 3;
      like server_extra('seq'), qr/auto_increment/i, '... and `seq` is AUTO_INCREMENT, with rows in the table';
      is_deeply server_keys(), { k_item => [ $kind => 'seq' ] }, '... and its key is the only one';

      $schema->storage->disconnect;
      $schema = schema_version(%{ $case->{to} });

      # every case drops the key of `seq`
      is_deeply upgrade_to($schema, allow_destructive => 1), \@ran, 'upgrade runs: ' . join ' ', @ran;
      is_deeply server_columns(), $case->{columns}, '... and the server has the columns of the schema, and no other';
      is_deeply server_keys(), {}, '... and no key';
      is server_type('seq'), $case->{type}{seq}, '... and `seq` has the type of the schema'
        if $case->{type}{seq};
      is_deeply $raw->selectall_arrayref("SELECT `id`, `note` FROM `$DB`.`item` ORDER BY `id`"),
        [ map { [ $_, $_ * 10 ] } 1 .. 3 ], '... and every row is still there';

      nothing_left $schema, '... and the next diff has nothing left';
      $schema->storage->disconnect;
    };
  }
}

subtest 'D: an AUTO_INCREMENT primary key changes its type' => sub {
  drop_database();
  $raw->do("CREATE DATABASE `$DB`");

  my $schema = schema_version(pk => 'int');
  unless (ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'the earlier schema installs') {
    diag "the install failed: $@";
    $schema->storage->disconnect;
    return;
  }
  $raw->do("INSERT INTO `$DB`.`item` (`note`) VALUES (?)", undef, $_) for 1 .. 2;
  $schema->storage->disconnect;
  $schema = schema_version(pk => 'bigint');

  is_deeply upgrade_to($schema), [ 'ALTER TABLE `item` MODIFY COLUMN `id` bigint NOT NULL AUTO_INCREMENT;' ],
    'upgrade runs the MODIFY with AUTO_INCREMENT';
  is server_type('id'), 'bigint', '... and `id` is a bigint';
  like server_extra('id'), qr/auto_increment/i, '... and still AUTO_INCREMENT';
  ok eval { $raw->do("INSERT INTO `$DB`.`item` (`note`) VALUES (?)", undef, 3); 1 },
    '... and an INSERT without an id works' or diag $@;
  is_deeply $raw->selectcol_arrayref("SELECT `id` FROM `$DB`.`item` ORDER BY `id`"), [ 1, 2, 3 ],
    '... and hands out the next id';
  nothing_left $schema, '... and the next diff has nothing left';
  $schema->storage->disconnect;
};

note 'warned during the run: ' . join ' | ', map { s/\s+\z//r } @warnings if @warnings;

drop_database();
$raw->disconnect;
undef $raw;

done_testing;
