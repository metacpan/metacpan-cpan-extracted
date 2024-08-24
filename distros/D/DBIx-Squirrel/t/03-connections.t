use Modern::Perl;
use open ':std', ':encoding(utf8)';
use Carp qw/croak/;
use Test::More;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

BEGIN {
    use_ok('DBIx::Squirrel') || print "Bail out!\n";
    use_ok('T::Squirrel')    || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

subtest 'connect to mock database' => sub {
    my $dbh = DBIx::Squirrel->connect(@MOCK_DB_CONNECT_ARGS);
    isa_ok($dbh, 'DBIx::Squirrel::db');

    $dbh->disconnect();
};

subtest 'connect to test database' => sub {
    my $dbh = DBIx::Squirrel->connect(@TEST_DB_CONNECT_ARGS);
    isa_ok($dbh, 'DBIx::Squirrel::db');

    $dbh->disconnect();
};

subtest 'clone connection to mock database' => sub {
    my $dbh = DBIx::Squirrel->connect(@MOCK_DB_CONNECT_ARGS);
    isa_ok($dbh, 'DBIx::Squirrel::db');

    my $clone = DBIx::Squirrel->connect($dbh);
    isa_ok($clone, 'DBIx::Squirrel::db');

    $clone->disconnect();
    $dbh->disconnect();
};

subtest 'clone connection to test database' => sub {
    my $dbh = DBIx::Squirrel->connect(@TEST_DB_CONNECT_ARGS);
    isa_ok($dbh, 'DBIx::Squirrel::db');

    my $clone = DBIx::Squirrel->connect($dbh);
    isa_ok($clone, 'DBIx::Squirrel::db');

    $clone->disconnect();
    $dbh->disconnect();
};

subtest 'clone connection created by DBI to mock database' => sub {
    my $dbh   = DBI->connect(@MOCK_DB_CONNECT_ARGS);
    my $clone = DBIx::Squirrel->connect($dbh);
    isa_ok($clone, 'DBIx::Squirrel::db');

    $clone->disconnect();
    $dbh->disconnect();
};

subtest 'clone connection created by DBI to test database' => sub {
    my $dbh   = DBI->connect(@TEST_DB_CONNECT_ARGS);
    my $clone = DBIx::Squirrel->connect($dbh);
    isa_ok($clone, 'DBIx::Squirrel::db');

    $clone->disconnect();
    $dbh->disconnect();
};

done_testing();
