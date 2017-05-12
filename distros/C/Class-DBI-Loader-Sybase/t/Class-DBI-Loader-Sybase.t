use strict;
use Test::More tests => 6;

use Class::DBI::Loader;
use DBI;

my $dbh;
my $database = $ENV{SYBASE_NAME};
my $user     = $ENV{SYBASE_USER};
my $password = $ENV{SYBASE_PASS};

SKIP: {

    eval { require Class::DBI::Sybase; require DBD::Sybase };
    skip "Class::DBI::Sybase is not installed", 6 if $@;
    skip "DBD::Sybase is too old; need at least version 1.05", 6
	if $DBD::Sybase::VERSION < 1.05;

    skip
      'You need to set the SYBASE_NAME, SYBASE_USER and SYBASE_PASS environment variables',
      6
      unless ( $database && $user );

    my $dsn = "dbi:Sybase:dbname=$database";
    $dbh = DBI->connect(
        $dsn, $user,
        $password,
        {
            RaiseError => 1,
            PrintError => 1,
            AutoCommit => 1
        }
    );

    $dbh->do(<<'SQL');
CREATE TABLE loader_test1 (
    id NUMERIC IDENTITY NOT NULL PRIMARY KEY ,
    dat VARCHAR(10)
)
SQL

    for my $dat (qw(foo bar baz)) {
        $dbh->do( "INSERT INTO loader_test1 (dat) VALUES('$dat')" );
    }

    $dbh->do(<<'SQL');
CREATE TABLE loader_test2 (
    id NUMERIC IDENTITY NOT NULL PRIMARY KEY,
    dat VARCHAR(10)
)
SQL

    for my $dat (qw(aaa bbb ccc ddd)) {
        $dbh->do( "INSERT INTO loader_test2 (dat) VALUES('$dat')" );
    }

    my $loader = Class::DBI::Loader->new(
        dsn        => $dsn,
        user       => $user,
        password   => $password,
        namespace  => 'SybTest',
        constraint => '^loader_test.*'
    );
    is( $loader->find_class("loader_test1"), "SybTest::LoaderTest1" );
    is( $loader->find_class("loader_test2"), "SybTest::LoaderTest2" );
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
}

END {
    if ($dbh) {
        $dbh->do("DROP TABLE loader_test1");
        $dbh->do("DROP TABLE loader_test2");
        $dbh->disconnect;
    }
}
