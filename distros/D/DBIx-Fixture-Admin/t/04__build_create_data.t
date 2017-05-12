use strict;
use Test::More 0.98;
use t::Util;

use DBIx::Fixture::Admin;
use DBIx::Sunny;
use DBIx::FixtureLoader;

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


subtest 'basic' => sub {
    teardown;
    $dbh->query("INSERT INTO test_hoge (name) value('aaa')");
    $dbh->query("INSERT INTO test_huga (name) value('aaa')");
    my $admin = DBIx::Fixture::Admin->new(
        dbh  => $dbh,
        conf => +{
            fixture_path  => './t/fixture/yaml/',
            ignore_tables => ['test_hoge'],
            driver        => 'mysql'
        }
    );

    my @data = $admin->_build_create_data(['test_hoge', 'test_huga']);

    is scalar @data, 1;
    is $data[0]->{table}, 'test_huga';
    is_deeply $data[0]->{columns}, ['id', 'name'];
    is $data[0]->{sql}, "SELECT `id`, `name`
FROM `test_huga`";

    my $yaml = DBIx::Fixture::Admin::_dump_yaml(
        $dbh,
        $data[0]->{table},
        $data[0]->{columns},
        $data[0]->{sql},
    );

    teardown;
    my $loader = DBIx::FixtureLoader->new(dbh => $dbh);
    $loader->load_fixture($yaml, table => "test_huga");

    my $rows = $dbh->select_all("SELECT * FROM test_huga;");
    is scalar @$rows, 1;
};

done_testing;

