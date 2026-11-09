use strict;
use warnings;
use Test::More;

# LIVE half of karr k80: DBIO::MySQL::Deploy->upgrade takes a column out of a
# table together with an index that was over it.
#
# WHY IT MATTERS. Dropping a column and the key over it is one edit of a
# schema, and an everyday one. The diff used to write every index statement
# after the column changes (t/40 has the offline half and pins the order), and
# the servers do not take the two in that order:
#   - an index goes along with the last column it was over, so the DROP INDEX
#     that followed the DROP COLUMN named an index that was gone, and the
#     upgrade ended with 1091 -- the database in the state the schema asked
#     for, the caller with an exception;
#   - MariaDB refuses to drop one column of a unique key over several (1072).
#     The upgrade ended at its first statement, and every later one did too:
#     that schema could not be reached by upgrade at all;
#   - MySQL drops such a column and keeps the key over the columns that are
#     left -- where the rows no longer have to differ. Rows the old schema
#     allowed and the new one allows as well were refused in between (1062).
# What the statements do in the order they are written now, only a server can
# say, and MySQL and MariaDB each say it for themselves.
#
# What this file claims, for a unique key and for a plain index alike, each
# time through upgrade() against a database that has the earlier version of the
# schema installed and rows in the table:
#   1. the only column of the key leaves the schema, and the key with it;
#   2. one of the two columns of the key leaves, and the key with it -- with
#      rows that are the same in the column that stays;
#   3. one of the two columns of the key leaves, and the key stays, over the
#      other column;
#   4. both columns of the key leave, and the key with them;
#   5. the key gets a column the same upgrade adds while one of its columns
#      gets another type: dropping an index early must not take the create
#      along, which needs the columns as they are afterwards.
# Every time upgrade runs the statements this file names, in that order, the
# server then has the columns and the keys of the schema and nothing else, the
# rows are still there, and the next diff has nothing left to say.
#
# NOT claimed, and the schema is built to stay clear of it:
#   - an index a foreign key needs, and where a DROP INDEX stands among the
#     foreign key statements (karr k81): no table here has a foreign key;
#   - DEFAULT in a diff (karr k78), and nullable columns, which t/88 asks
#     (karr k87): every column is NOT NULL and none has a default;
#   - text columns (karr k82): the columns are numbers;
#   - an AUTO_INCREMENT column that is not the primary key and loses the only
#     key it has: t/105 asks that (karr k80, karr k93). The AUTO_INCREMENT
#     column here is the primary key, which no upgrade touches.
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

my $DB = "dbio_k80_$$";

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
# One version of the schema, connected to the database of this test:
#   columns => [ names ]            # beside the primary key `id`; all NOT NULL
#   type    => { name => type }     # where a column is not an int
#   key     => [ columns ]          # the key `k_item`, or none
#   kind    => 'unique' | 'plain'   # add_unique_constraint or mysql_index
my $version = 0;
sub schema_version {
  my (%def) = @_;
  my $ns    = 'K80Live::V' . ++$version;
  my $class = "${ns}::Result::Item";
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
  $class->table('item');
  $class->add_columns(
    id => { data_type => 'int', is_auto_increment => 1 },
    # `extra` is added to a table that holds rows: a default, or upgrade refuses it
    # (DBIO::MySQL::Deploy::_refuse_unfillable, karr k120)
    map { $_ => { data_type => $def{type}{$_} // 'int', ($_ eq 'extra' ? (default_value => 0) : ()) } } @{ $def{columns} },
  );
  $class->set_primary_key('id');
  if ($def{key}) {
    $def{kind} eq 'unique'
      ? $class->add_unique_constraint(k_item => $def{key})
      : $class->mysql_index(k_item => { columns => $def{key} });
  }
  $ns->register_class(Item => $class);
  # Every connection of the schema works in this test's database, whatever
  # the DSN names.
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

# What the server has of `item`: its columns in their order, and its keys
# without the primary one, name => [ 'unique' or 'plain', columns in order ].
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
# The rows, as tenant, code, note. Under DISTINCT no code is there twice, so a
# unique key over `code` alone holds them. Under REPEATED one is: the rows
# differ in tenant and code together and in nothing less, which is all a key
# over the two asks, and all a schema without the key asks.
my @DISTINCT = ([ 1, 10, 1 ], [ 1, 20, 2 ], [ 2, 30, 3 ]);
my @REPEATED = ([ 1, 10, 1 ], [ 2, 10, 2 ], [ 2, 20, 3 ]);
my @ALL      = qw(tenant code note);

my $DROP_KEY = 'DROP INDEX `k_item` ON `item`;';
sub drop_column { "ALTER TABLE `item` DROP COLUMN `$_[0]`;" }

# from / to: the key and the columns of the schema before and after. `ran` is
# what upgrade has to run; __CREATE__ in it is CREATE INDEX or CREATE UNIQUE
# INDEX, by the kind of the case.
my @CASES = (
  {
    name => 'the only column of the key leaves, and the key with it',
    rows => \@DISTINCT,
    from => { columns => \@ALL, key => ['code'] },
    to   => { columns => [qw(tenant note)] },
    ran  => [ $DROP_KEY, drop_column('code') ],
  },
  {
    name => 'one of the two columns of the key leaves, and the key with it',
    rows => \@REPEATED,
    from => { columns => \@ALL, key => [qw(tenant code)] },
    to   => { columns => [qw(code note)] },
    ran  => [ $DROP_KEY, drop_column('tenant') ],
  },
  {
    name => 'one of the two columns of the key leaves, and the key stays over the other',
    rows => \@DISTINCT,
    from => { columns => \@ALL, key => [qw(tenant code)] },
    to   => { columns => [qw(code note)], key => ['code'] },
    ran  => [ $DROP_KEY, drop_column('tenant'), '__CREATE__ `k_item` ON `item` (`code`) USING BTREE;' ],
  },
  {
    name => 'both columns of the key leave, and the key with them',
    rows => \@REPEATED,
    from => { columns => \@ALL, key => [qw(tenant code)] },
    to   => { columns => ['note'] },
    ran  => [ $DROP_KEY, drop_column('code'), drop_column('tenant') ],
  },
  {
    name => 'the key gets a column the upgrade adds, and one of its columns another type',
    rows => \@DISTINCT,
    from => { columns => \@ALL, key => ['code'] },
    to   => { columns => [ @ALL, 'extra' ], type => { code => 'bigint' }, key => [qw(code extra)] },
    ran  => [
      $DROP_KEY,
      'ALTER TABLE `item` MODIFY COLUMN `code` bigint NOT NULL;',
      'ALTER TABLE `item` ADD COLUMN `extra` int NOT NULL DEFAULT \'0\';',
      '__CREATE__ `k_item` ON `item` (`code`, `extra`) USING BTREE;',
    ],
  },
);

for my $kind (qw(unique plain)) {
  my $create = $kind eq 'unique' ? 'CREATE UNIQUE INDEX' : 'CREATE INDEX';

  for my $case (@CASES) {
    subtest "$kind key: $case->{name}" => sub {
      my ($from, $to) = @$case{qw(from to)};
      my @ran = map { s/\A__CREATE__/$create/r } @{ $case->{ran} };

      # Every case starts from a database of its own making: a case that does
      # not get through must not be what the next one starts from.
      drop_database();
      $raw->do("CREATE DATABASE `$DB`");

      my $schema = schema_version(%$from, kind => $kind);
      unless (ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'the earlier schema installs') {
        diag "the install failed, and nothing of this case can be asked: $@";
        $schema->storage->disconnect;
        return;
      }
      $raw->do("INSERT INTO `$DB`.`item` (`tenant`, `code`, `note`) VALUES (?, ?, ?)", undef, @$_)
        for @{ $case->{rows} };
      is_deeply server_keys(), { k_item => [ $kind => @{ $from->{key} } ] },
        '... and the table has the key, over the columns it is to lose, and rows';

      $schema->storage->disconnect;
      $schema = schema_version(%$to, kind => $kind);

      # a case that drops a column is released for it; the one that only changes the key and the type is not
      my $ran = upgrade_to($schema, allow_destructive => (grep { /DROP COLUMN/ } @ran) ? 1 : 0);
      is_deeply $ran, \@ran, 'upgrade runs: ' . join ' ', @ran;

      is_deeply server_columns(), [ id => @{ $to->{columns} } ],
        '... and the server has the columns of the schema, and no other';
      is_deeply server_keys(), ($to->{key} ? { k_item => [ $kind => @{ $to->{key} } ] } : {}),
        $to->{key} ? '... and the key over the columns the schema names' : '... and no key';

      # The rows, in the columns that were there before and are there still.
      my %at   = (tenant => 0, code => 1, note => 2);
      my @kept = grep { exists $at{$_} } @{ $to->{columns} };
      is_deeply $raw->selectall_arrayref(
          'SELECT ' . join(', ', map { "`$_`" } @kept) . " FROM `$DB`.`item` ORDER BY `id`"),
        [ map { my $row = $_; [ map { $row->[ $at{$_} ] } @kept ] } @{ $case->{rows} } ],
        '... and every row is still there, with what it had in the columns that stayed';

      nothing_left $schema, '... and the next diff has nothing left';
      $schema->storage->disconnect;
    };
  }
}

note 'warned during the run: ' . join ' | ', map { s/\s+\z//r } @warnings if @warnings;

drop_database();
$raw->disconnect;
undef $raw;

done_testing;
