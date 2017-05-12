use strict;
use Test::More 0.98;
use Test::Exception;
use t::Util;

use DBIx::Fixture::Admin;
use DBIx::Sunny;

my $dbh = DBIx::Sunny->connect( $ENV{TEST_MYSQL} );

sub teardown {
    eval {
        $dbh->query("DROP TABLE `test_hoge`");
        $dbh->query("DROP TABLE `test_huga`");
    };

    my @create_sqls = (
        "CREATE TABLE `test_hoge` (
          `id` integer unsigned NOT NULL auto_increment,
          `name` VARCHAR(32) NOT NULL,
          PRIMARY KEY (`id`)
        );",

        "CREATE TABLE `test_huga` (
          `id` integer unsigned NOT NULL auto_increment,
          `name` VARCHAR(32) NOT NULL,
          PRIMARY KEY (`id`)
        );",
    );

    $dbh->query($_) for @create_sqls;
}


subtest 'can fixture load' => sub {
    teardown;

    my $select_hoge_sql = "SELECT * FROM test_hoge;";
    my $rows = $dbh->select_all($select_hoge_sql);
    is scalar @$rows, 0;

    my $admin = DBIx::Fixture::Admin->new(
        dbh  => $dbh,
        conf => +{
            fixture_path  => './t/fixture/csv/',
            fixture_type  => 'csv',
            ignore_tables => ['test_huga'],
        }
    );

    $admin->load(['test_hoge', 'test_huga']);
    $rows = $dbh->select_all($select_hoge_sql);
    is scalar @$rows, 3;

    $rows = $dbh->select_all("SELECT * FROM test_huga;");
    is scalar @$rows, 0;
};

subtest 'no such fixture' => sub {
    teardown;
    local $SIG{__WARN__} = sub { fail shift };

    my $admin = DBIx::Fixture::Admin->new(
        dbh  => $dbh,
        conf => +{
            fixture_path  => './t/fixture/csv/not_exist',
            fixture_type  => 'csv',
        }
    );

    lives_ok {
        $admin->load(['test_hoge']);
    };
};

done_testing;

