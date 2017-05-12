use strict;
use Test::More tests => 8;

use DBIx::Class::Loader;
use DBI;

my $dbh;
my $database = $ENV{ADO_NAME};
my $user     = $ENV{ADO_USER};
my $password = $ENV{ADO_PASS};

SKIP: {
    skip
'You need to set the ADO_NAME, ADO_USER and ADO_PASS environment variables',
      8
      unless ( $database );

    my $dsn = "dbi:ADO:$database";
    $dbh = DBI->connect(
        $dsn, $user,
        $password,
        {
            RaiseError => 1,
            PrintError => 1
        }
    );

    $dbh->do(<<'SQL');
CREATE TABLE loader_test1 (
    id INT IDENTITY (1, 1) NOT NULL PRIMARY KEY,
    dat VARCHAR(32)
)
SQL

    my $sth = $dbh->prepare(<<"SQL");
INSERT INTO loader_test1 (dat) VALUES(?)
SQL
    for my $dat (qw(foo bar baz)) {
        $sth->execute($dat);
        $sth->finish;
    }

    $dbh->do(<<'SQL');
CREATE TABLE loader_test2 (
    id INT IDENTITY (1, 1) NOT NULL PRIMARY KEY,
    fk INT NOT NULL REFERENCES loader_test1( id ),
    dat VARCHAR(32)
)
SQL

    $sth = $dbh->prepare(<<"SQL");
INSERT INTO loader_test2 (fk, dat) VALUES(?,?)
SQL
    for my $dat ([ 1, 'aaa' ],[ 1, 'bbb' ],[ 1, 'ccc' ],[ 1, 'ddd' ]) {
        $sth->execute(@$dat);
        $sth->finish;
    }
    $sth->finish;

    my $loader = DBIx::Class::Loader->new(
        dsn           => $dsn,
        user          => $user,
        password      => $password,
        namespace     => 'ADOTest',
        relationships => 1,
        constraint    => '^loader_test.+',
    );
    is( $loader->find_class("loader_test1"), "ADOTest::LoaderTest1" );
    is( $loader->find_class("loader_test2"), "ADOTest::LoaderTest2" );
    my $class1 = $loader->find_class("loader_test1");
    my $obj    = $class1->find(1);
    is( $obj->id,  1 );
    is( $obj->dat, "foo" );
    my $class2 = $loader->find_class("loader_test2");
    is( $class2->count, 4 );
    my ($obj2) = $class2->find( dat => 'bbb' );
    is( $obj2->id, 2 );
    ok( $obj->can( 'loadertest2s' ) );
    my( @objs ) = $obj->loadertest2s;
    is( scalar @objs, 4 );
}

END {
    if ($dbh) {
        $dbh->do("DROP TABLE loader_test1");
        $dbh->do("DROP TABLE loader_test2");
        $dbh->disconnect;
    }
}
