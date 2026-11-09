use strict;
use warnings;
use Test::More;

# LIVE half of karr k95 (t/119 has the offline half and the reasoning): upgrade
# removes the default of a column that the schema no longer gives one, and the
# next diff has nothing left.
#
# WHY IT MATTERS. The target of an upgrade is the introspection of a temporary
# database; there a column without a default has default_value undef, and the
# comparison read that as "not prescribed" -- upgrade said there was nothing to
# do, and the default stayed in the database. Nothing worked this way on either
# server (on MariaDB a nullable column ended in error 1067 or in a default of
# the word NULL before karr k87; since then the silent nothing, as on MySQL).
#
# What this file claims, against a database that has the columns with defaults
# and a schema that names none:
#   1. the introspection reads the defaults the table was made with: a number,
#      a string, a string that is the word NULL, and DEFAULT CURRENT_TIMESTAMP
#      (an expression: EXTRA DEFAULT_GENERATED on MySQL, the quoted/bare text
#      on MariaDB);
#   2. upgrade writes one MODIFY COLUMN per such column, none with a DEFAULT;
#   3. a row inserted without the columns then gets NULL in the nullable ones,
#      and the server refuses the row without the NOT NULL one (it has no
#      default to fall back on any more) -- that is the default gone, not only
#      the model;
#   4. the next diff has nothing left, and a second upgrade does nothing;
#   5. a column whose schema still names its default keeps it through the same
#      upgrade.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in a database of its own, created and dropped here (see t/88).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;
use DBIO::MySQL::Introspect;

my $DB = "mysql_k95_$$";

my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });

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
note sprintf 'server %s', scalar $raw->selectrow_array('SELECT VERSION()');

$raw->do(<<"SQL");
CREATE TABLE `$DB`.`item` (
  `id`    int NOT NULL AUTO_INCREMENT,
  `num`   int NULL DEFAULT 5,
  `str`   varchar(20) NOT NULL DEFAULT 'x',
  `word`  varchar(20) NULL DEFAULT 'NULL',
  `stamp` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `keep`  int NOT NULL DEFAULT 7,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
SQL

sub read_defaults {
  $raw->do("USE `$DB`");
  my $columns = DBIO::MySQL::Introspect->new(dbh => $raw)->model->{columns}{item};
  return { map { $_->{column_name} => $_->{default_value} } @$columns };
}

my $before = read_defaults();
is_deeply [ map { defined $before->{$_} ? 1 : 0 } qw(num str word stamp keep) ], [ (1) x 5 ],
  'the introspection reads a default for each of the columns the table was made with'
  or diag explain $before;

my $ns = 'K95Live::V1';
eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
{
  my $class = "${ns}::Result::Item";
  eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
  $class->table('item');
  $class->add_columns(
    id    => { data_type => 'int', is_auto_increment => 1 },
    num   => { data_type => 'int', is_nullable => 1 },
    str   => { data_type => 'varchar', size => 20 },
    word  => { data_type => 'varchar', size => 20, is_nullable => 1 },
    stamp => { data_type => 'datetime', is_nullable => 1 },
    keep  => { data_type => 'int', default_value => 7 },
  );
  $class->set_primary_key('id');
  $ns->register_class(Item => $class);
}
my $schema = $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });

my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade };
ok $diff && !$@, 'upgrade runs' or diag "upgrade failed: $@";
my @sql = $diff ? map { s/\b(int)\(\d+\)/$1/gr } map { $_->as_sql } @{ $diff->operations } : ();
note "  $_" for @sql;
is_deeply \@sql, [
  'ALTER TABLE `item` MODIFY COLUMN `num` int;',
  'ALTER TABLE `item` MODIFY COLUMN `stamp` datetime;',
  'ALTER TABLE `item` MODIFY COLUMN `str` varchar(20) NOT NULL;',
  'ALTER TABLE `item` MODIFY COLUMN `word` varchar(20);',
],'... one MODIFY COLUMN for each column that lost its default, none with a DEFAULT, and none for `keep`'
  or diag explain \@sql;

my $after = read_defaults();
is_deeply [ map { $after->{$_} } qw(num str word stamp) ], [ (undef) x 4 ],
  '... and the introspection reads no default for them any more';
is $after->{keep}, 7, '... while `keep` still has its own';

ok eval { $raw->do("INSERT INTO `$DB`.`item` (`str`) VALUES ('s')"); 1 }, 'a row that names only the string' or diag $@;
is_deeply $raw->selectall_arrayref("SELECT `num`, `str`, `word`, `stamp`, `keep` FROM `$DB`.`item`"),
  [ [ undef, 's', undef, undef, 7 ] ],
  '... gets NULL in the nullable columns (not 5, not the word, not the time) and its default in `keep`';

{
  local $raw->{PrintError} = 0;
  ok !eval { $raw->do("INSERT INTO `$DB`.`item` (`num`) VALUES (1)"); 1 },
    '... and a row without the NOT NULL string is refused: it has no default any more';
}

my $again = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
ok $again && !$again->has_changes, 'the next diff has nothing left'
  or diag $again ? explain [ map { $_->as_sql } @{ $again->operations } ] : "the diff failed: $@";

my $second = eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade };
ok !$@ && (!$second || !$second->has_changes), 'a second upgrade has nothing to do' or diag $@;

$schema->storage->disconnect;
drop_database();
$raw->disconnect;
undef $raw;

done_testing;
