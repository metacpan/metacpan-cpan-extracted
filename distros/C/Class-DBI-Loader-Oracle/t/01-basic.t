use Test::More;
use strict; use warnings;

BEGIN {
    my @required_modules = qw/ DBD::Oracle Class::DBI::Oracle Class::DBI::Loader /;
    my $use_statements = 'use ' . (join '; use ', @required_modules) . ';';
    my $skip_message =
	  "all: failed to load one or more of these required modules:\n"
	. (join "\n", @required_modules);
    eval $use_statements;
    plan skip_all => $skip_message if $@;

    use vars qw/ $dsn $user $dbh /;
    $dsn = 'dbi:Oracle:';
    $user = $ENV{ORACLE_USERID} || 'scott/tiger';
    eval { $dbh = DBI->connect($dsn, $user, '') or die $DBI::errstr };
    plan skip_all => 'all: failed to connect to Oracle. Try setting ORACLE_USERID=user/pass@sid.' if $@;

    plan tests => 6;
}

$dbh->do(<<'SQL');
 CREATE TABLE loader_test1 (
     id INTEGER PRIMARY KEY,
     dat VARCHAR2(10)
 )
SQL

my $sth = $dbh->prepare(<<"SQL");
 INSERT INTO loader_test1 (id,dat) VALUES(?,?)
SQL

my %test1 = (1 => 'foo', 2 => 'bar', 3 => 'baz');
while (my ($id,$dat) = each %test1) {
    $sth->execute($id,$dat);
    $sth->finish;
}

$dbh->do(<<'SQL');
 CREATE TABLE loader_test2 (
     id INTEGER PRIMARY KEY,
     dat VARCHAR2(10)
 )
SQL

$sth = $dbh->prepare(<<"SQL");
 INSERT INTO loader_test2 (id,dat) VALUES(?,?)
SQL

my %test2 = (1 => 'aaa', 2 => 'bbb', 3 => 'ccc', 4 => 'ddd');
while (my ($id,$dat) = each %test2) {
    $sth->execute($id,$dat);
    $sth->finish;
}

my $loader = Class::DBI::Loader->new
(
 dsn        => $dsn,
 user       => $user,
 #password   => $password,
 namespace  => 'OracleTest',
 constraint => '^loader_test.*'
);

is( $loader->find_class("loader_test1"), "OracleTest::LoaderTest1" );
is( $loader->find_class("loader_test2"), "OracleTest::LoaderTest2" );
my $class1 = $loader->find_class("loader_test1");
my $obj    = $class1->retrieve(1);
is( $obj->id,  1 );
is( $obj->dat, "foo" );
my $class2 = $loader->find_class("loader_test2");
is( $class2->retrieve_all, 4 );
my ($obj2) = $class2->search( dat => 'bbb' );
is( $obj2->id, 2 );

$class1->db_Main->disconnect;
$class2->db_Main->disconnect;

END {
    if ($dbh) {
        $dbh->do("DROP TABLE loader_test1");
        $dbh->do("DROP TABLE loader_test2");
        $dbh->disconnect;
     }
}
