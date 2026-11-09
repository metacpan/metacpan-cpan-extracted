use strict;
use warnings;
use Test::More;

# LIVE half of karr k120 (t/123 has the offline half): a source named
# database.table is made in that database, and the install refuses a database
# the server does not have.
#
# WHY IT MATTERS. Until k120 (and since k89) such a name was refused; before
# k89 it silently made a table literally called `db.t`. Claims, on MySQL and on
# MariaDB:
#   1. install makes the table in the other database -- and none in the
#      database of the connection, none with a dot in its name;
#   2. the table is the one the SQLMaker reads: a row goes in and comes out
#      through the resultset;
#   3. the diff after the install is empty, and upgrade has nothing to do (the
#      diff reads the current database; the table of the other one is
#      installed, not compared), and the temporary database of the diff holds
#      nothing of it;
#   4. install with add_drop_table over the filled table runs through;
#   5. a database the server does not have ends the install before its first
#      statement, with an exception naming the table AND the database; nothing
#      is created, in the case's database either.
# Works in two databases of its own, created and dropped here.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;

my ($DB, $OTHER, $GONE) = map { "dbio_k120${_}_$$" } qw(a b c);
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });

sub drop_databases { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$_`") for $DB, $OTHER, $GONE }
END { if ($raw) { local ($@, $?); eval { drop_databases() } } }

unless (eval { drop_databases(); $raw->do("CREATE DATABASE `$_`") for $DB, $OTHER; 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create databases of its own: $why";
}
note sprintf 'server %s, databases %s %s', scalar $raw->selectrow_array('SELECT VERSION()'), $DB, $OTHER;

my $n = 0;
sub make_schema {
  my ($table) = @_;
  my $ns = 'K120Live::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  my $class = "${ns}::Result::T";
  eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
  $class->table($table);
  $class->add_columns(id => { data_type => 'int' }, name => { data_type => 'varchar', size => 20, is_nullable => 1 });
  $class->set_primary_key('id');
  $ns->register_class(T => $class);
  return $ns->connect(
    $dsn =~ s/\b(?:database|dbname)=[^;]*/database=$DB/ir, $user, $pass,
    { on_connect_do => ["USE `$DB`"] });
}

sub tables_of {
  my ($db) = @_;
  return [ map { $_->[0] } @{ $raw->selectall_arrayref(
    'SELECT table_name FROM information_schema.tables WHERE table_schema = ? ORDER BY 1', undef, $db) } ];
}

my $schema = make_schema("$OTHER.t");
ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'install runs' or diag $@;
is_deeply tables_of($OTHER), ['t'], '1: the table is in the other database';
is_deeply tables_of($DB), [], '... and the connection\'s database holds nothing, no table with a dot either';

my $row = eval {
  $schema->resultset('T')->create({ id => 1, name => 'x' });
  $schema->resultset('T')->find(1);
};
is $row && $row->name, 'x', '2: a row goes in and comes out through the resultset' or diag $@;

my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
is $@, '', '3: the diff runs';
ok $diff && !$diff->has_changes, '... and is empty' or diag $diff && $diff->as_sql;
ok !DBIO::MySQL::Deploy->new(schema => $schema)->upgrade, '... upgrade has nothing to do';
is_deeply [ grep { /^_dbio_tmp_/ } @{ $raw->selectcol_arrayref('SHOW DATABASES') } ], [],
  '... and no temporary database is left';
is_deeply tables_of($OTHER), ['t'], '... the table of the other database is as it was';

ok eval { DBIO::MySQL::Deploy->new(schema => $schema, add_drop_table => 1)->install; 1 },
  '4: install with add_drop_table over the filled table runs' or diag $@;
is $raw->selectrow_array("SELECT COUNT(*) FROM `$OTHER`.`t`"), 0, '... and made it new';
$schema->storage->disconnect;

# 5.
my $lost = make_schema("$GONE.t");
my $ok = eval { DBIO::MySQL::Deploy->new(schema => $lost)->install; 1 };
my $err = $@;
ok !$ok, '5: a database the server does not have ends the install';
ok ref $err && $err->isa('DBIO::Exception'), '... with a DBIO::Exception' or diag "$err";
like "$err", qr/refuses/, '... that says it refuses';
like "$err", qr/\Q$GONE.t\E/, '... names the table';
like "$err", qr/database \Q$GONE\E does not exist/, '... and the database';
is_deeply tables_of($DB), [], '... and nothing was made in the database of the connection';
ok !scalar $raw->selectrow_array('SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = ?', undef, $GONE),
  '... nor the database';
$lost->storage->disconnect;

done_testing;
