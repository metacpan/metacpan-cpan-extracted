use strict;
use Test::More 0.98;

use FindBin;
use lib "$FindBin::Bin/../";

use t::Util;

use DBIx::Fixture::Admin;
use DBIx::Sunny;

my $dbh = DBIx::Sunny->connect( $ENV{TEST_MYSQL} );

subtest 'basic' => sub {
    my $admin = DBIx::Fixture::Admin->new(
        dbh  => $dbh,
        conf => +{
            fixture_path  => './t/fixture/yaml/',
            ignore_tables => ['test_hoge']
        }
    );

    my @tables = $admin->_difference_ignore_tables(['test_hoge', 'test_huga']);

    is scalar @tables, 1;
    is $tables[0], 'test_huga';
};

subtest 'no ignore' => sub {
    my $admin = DBIx::Fixture::Admin->new(
        dbh  => $dbh,
        conf => +{
            fixture_path  => './t/fixture/yaml/',
        }
    );

    my @tables = $admin->_difference_ignore_tables(['test_hoge', 'test_huga']);

    is scalar @tables, 2;
};

subtest 'regex ignore' => sub {
    my $admin = DBIx::Fixture::Admin->new(
        dbh  => $dbh,
        conf => +{
            fixture_path  => './t/fixture/yaml/',
            ignore_tables => ['test_.*']
        }
    );

    my @tables = $admin->_difference_ignore_tables(['test_hoge', 'test_huga']);

    is scalar @tables, 0;

    $admin = DBIx::Fixture::Admin->new(
        dbh  => $dbh,
        conf => +{
            fixture_path  => './t/fixture/yaml/',
            ignore_tables => ['.*_hoge']
        }
    );

    @tables = $admin->_difference_ignore_tables(['test_hoge', 'test_huga']);

    is scalar @tables, 1;
    is scalar $tables[0], 'test_huga';
};

done_testing;

