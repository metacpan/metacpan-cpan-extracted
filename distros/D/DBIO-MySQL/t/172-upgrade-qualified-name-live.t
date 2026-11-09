use strict;
use warnings;
use Test::More;

# LIVE half of karr k122 (t/171 has the offline half): upgrade treats a table
# named database.table as install does (karr k120) -- it is made in, and
# compared in, that database.
#
# WHY IT MATTERS. k120 made install create `other`.`t`, but the diff read the
# current database alone: a table of another database that a new version of the
# schema adds was neither compared nor created, and upgrade said "nothing to
# do". That is a silent omission, the worst kind. Claims, on MySQL and MariaDB:
#   1. upgrade creates a table that is new in another database, there, and
#      none in the database of the connection;
#   2. a table both versions have in the other database is compared as the
#      current database's tables are: a column and an index the new version
#      adds are added to `other`.`t`, the rows stay, and the diff is empty after;
#   3. a database the server does not have ends upgrade before its first
#      statement, naming table and database -- the local table the same diff
#      would have created is not created;
#   4. a NOT NULL column without default added to a table of another database
#      that holds rows is refused like one of the current database;
#   5. no temporary database is left, and a table of the other database that
#      the schema does not name is left alone.
# Works in databases of its own, created and dropped here; the other one has
# another default character set than the tables the driver makes in it.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;

my ($DB, $OTHER, $GONE) = map { "dbio_k122${_}_$$" } qw(a b c);
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });

sub drop_databases { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$_`") for $DB, $OTHER, $GONE }
END { if ($raw) { local ($@, $?); eval { drop_databases() } } }

unless (eval { drop_databases(); $raw->do("CREATE DATABASE `$DB`"); $raw->do("CREATE DATABASE `$OTHER` CHARACTER SET latin1"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create databases of its own: $why";
}
note sprintf 'server %s, databases %s %s', scalar $raw->selectrow_array('SELECT VERSION()'), $DB, $OTHER;

my $n = 0;
# spec: [ table => { col => {info} }, { index => [cols] } ] ...
sub make_schema {
  my (@sources) = @_;
  my $ns = 'K122Live::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  my $i = 0;
  for my $spec (@sources) {
    my ($table, $columns, $indexes) = @$spec;
    my $class = "${ns}::Result::T" . ++$i;
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table($table);
    $class->add_columns(id => { data_type => 'int' }, @$columns);
    $class->set_primary_key('id');
    $class->mysql_index($_ => { columns => $indexes->{$_} }) for sort keys %{ $indexes || {} };
    $ns->register_class("T$i" => $class);
  }
  return $ns->connect(
    $dsn =~ s/\b(?:database|dbname)=[^;]*/database=$DB/ir, $user, $pass,
    { on_connect_do => ["USE `$DB`"] });
}

sub tables_of {
  my ($db) = @_;
  return [ map { $_->[0] } @{ $raw->selectall_arrayref(
    'SELECT table_name FROM information_schema.tables WHERE table_schema = ? ORDER BY 1', undef, $db) } ];
}
sub columns_of {
  my ($db, $t) = @_;
  return [ map { $_->[0] } @{ $raw->selectall_arrayref(
    'SELECT column_name FROM information_schema.columns WHERE table_schema = ? AND table_name = ? ORDER BY ordinal_position', undef, $db, $t) } ];
}
sub indexes_of {
  my ($db, $t) = @_;
  return [ map { $_->[0] } @{ $raw->selectall_arrayref(
    q{SELECT DISTINCT index_name FROM information_schema.statistics WHERE table_schema = ? AND table_name = ? AND index_name <> 'PRIMARY' ORDER BY 1}, undef, $db, $t) } ];
}
sub upgrade_of {
  my ($schema) = @_;
  return DBIO::MySQL::Deploy->new(schema => $schema)->upgrade;
}

my $name = [ name => { data_type => 'varchar', size => 20, is_nullable => 1 } ];

# version 1: a local table and one table of the other database
my $v1 = make_schema([ local_a => $name ], [ "$OTHER.t" => $name ]);
ok eval { DBIO::MySQL::Deploy->new(schema => $v1)->install; 1 }, 'install of version 1' or diag $@;
$raw->do("INSERT INTO `$OTHER`.`t` (id, name) VALUES (1, 'x')");
$raw->do("CREATE TABLE `$OTHER`.`not_ours` (id INT)");
$v1->storage->disconnect;

# 1. + 2. version 2: a new table in the other database, a column and an index on the old one
my $v2 = make_schema(
  [ local_a => $name ],
  [ "$OTHER.t" => [ @$name, note => { data_type => 'varchar', size => 10, is_nullable => 1 } ], { by_name => ['name'] } ],
  [ "$OTHER.u" => $name ],
);
my $diff = eval { DBIO::MySQL::Deploy->new(schema => $v2)->diff };
is $@, '', 'the diff of version 2 runs';
ok $diff && $diff->has_changes, '... and sees the changes' or diag 'no changes';
my $up = eval { upgrade_of($v2) };
is $@, '', '1: upgrade runs';
is_deeply tables_of($OTHER), [qw(not_ours t u)], '1: the new table is made in the other database';
is_deeply tables_of($DB), ['local_a'], '... and none in the database of the connection';
is_deeply columns_of($OTHER, 't'), [qw(id name note)], '2: the column the new version adds is added to the table of the other database';
is_deeply indexes_of($OTHER, 't'), ['by_name'], '... and the index';
is $raw->selectrow_array("SELECT name FROM `$OTHER`.`t` WHERE id = 1"), 'x', '... the row is still there';
my $again = eval { DBIO::MySQL::Deploy->new(schema => $v2)->diff };
ok $again && !$again->has_changes, '... and the diff after it is empty' or diag $again && $again->as_sql;
is_deeply tables_of($OTHER), [qw(not_ours t u)], '5: a table of the other database the schema does not name is left alone';
is_deeply [ grep { /^_dbio_tmp_/ } @{ $raw->selectcol_arrayref('SHOW DATABASES') } ], [],
  '5: no temporary database is left';

# 4. NOT NULL without default, rows in the table
my $v3 = make_schema(
  [ local_a => $name ],
  [ "$OTHER.t" => [ @$name, note => { data_type => 'varchar', size => 10, is_nullable => 1 },
                    must => { data_type => 'int' } ], { by_name => ['name'] } ],
  [ "$OTHER.u" => $name ],
);
my $ok = eval { upgrade_of($v3); 1 };
my $err = $@;
ok !$ok, '4: a NOT NULL column without default on a filled table of another database is refused';
like "$err", qr/refuses to add the column t\.must/, '... naming the column' or diag "$err";
is_deeply columns_of($OTHER, 't'), [qw(id name note)], '... and the table is as it was';
$v3->storage->disconnect;

# 3. a database that is not there
my $v4 = make_schema(
  [ local_a => $name ],
  [ local_new => $name ],
  [ "$GONE.t" => $name ],
);
$ok = eval { upgrade_of($v4); 1 };
$err = $@;
ok !$ok, '3: a database the server does not have ends upgrade';
ok ref $err && $err->isa('DBIO::Exception'), '... with a DBIO::Exception' or diag "$err";
like "$err", qr/refuses/, '... that says it refuses';
like "$err", qr/\Q$GONE.t\E/, '... names the table';
like "$err", qr/database \Q$GONE\E does not exist/, '... and the database';
is_deeply tables_of($DB), ['local_a'], '... and the local table the diff would have made is not made';
ok !scalar $raw->selectrow_array('SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = ?', undef, $GONE),
  '... nor the database';
is_deeply [ grep { /^_dbio_tmp_/ } @{ $raw->selectcol_arrayref('SHOW DATABASES') } ], [], '... and no temporary database is left';
$v4->storage->disconnect;

done_testing;
