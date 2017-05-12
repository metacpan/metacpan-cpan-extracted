#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::MigrationTest;
use Test::More;
use DBIx::Transaction;
use DBIx::Migration::Directories;

our($driver, $migration, $migration2, $sth, $dbh, $rv, $row, @sql);

my @tests = (
    sub {
        is($migration->detect_desired_version, 4, 'Desired version is 4');
    },
    sub {
        ok(
            $migration->full_migrate(
                dir             => "schema/$driver",
                common_dir      =>  "schema/_common",
            ),
            'Install latest schema'
        ),
    },
    sub {
        ok($migration->get_current_version == 4, 'At version 4');
    },
    sub {
        ok($migration->migrate_to(3), 'Migrate down to version 3'),
    },
    sub {
        ok($migration->get_current_version == 3, 'At version 3');
    },
    sub {
        is(
            $migration->detect_desired_version,
            3,
            'No upgrades, desired version is 3'
        );
    },
    sub {
        eval { $migration->migrate_to(4) };
        like($@, qr/^No migrations in direction 1 for 3/, "Can't get to 4");
    },
    sub {
        ok($migration->migrate_to(2.5), 'Downgrade to 2.5');
    },
    sub {
        diag("Expect a duplicate key warning here");
        $migration->{current_version} = 1;
        ok(!$migration->migrate_to(2.5), "Can't migrate with version mismatch");
    },
    sub {
        ok($migration->get_current_version == 2.5, 'At version 2.5');
    },
    sub {
        delete $migration->{desired_version};
        eval { $migration->migrate };
        like($@, qr/migrate called without desired_version/,
            "Can't migrate without a desired version"
        );
    },
    sub {
        ok($migration->set_desired_version == 4, 'We can get to version 4 again');
    },
    sub {
        ok($migration->migrate_to(1), 'Downgrade to 1');
    },
    sub {
        ok($migration->get_current_version == 1, 'At version 1');
    },
    sub {
        ok($migration->detect_desired_version == 4, 'We can get to version 4');
    },
    sub {
        eval { $migration->full_delete_schema };
        like($@, qr/^No migrations in direction -1/, 'No way to remove schema');
    },
    sub {
        ok(
            $migration->full_migrate(
                dir => "schema/$driver", common_dir => "schema/_common"
            ),
            'Do a full migrate from 1'
        );
    },
    sub {
        ok($migration->get_current_version == 4, 'At version 4 again');
    },
    sub {
        ok(
            $migration2->full_migrate(
                dir => "schema/$driver",
                common_dir => "schema/_common"
            ),
            'Migrate in second schema'
        );
    },
    sub {
        ok(
            $migration->full_delete_schema(
                dir => "schema/$driver", common_dir => "schema/_common"
            ),
            'Schema removed'
        );
    },
    sub {
        ok(!$migration->get_current_version, 'Schema is removed');
    },
    sub {
        diag("Expect a non-existant table warning here");
        $migration->{current_version} = 2.5;
        ok(
            !$migration->delete_schema,
            "Can't delete schema with version mismatch"
        );
    },
    sub {
        ok(
            $migration2->full_delete_schema(
                dir             => "schema/$driver",
                common_dir      => "schema/_common"
            ),
            'Second schema removed OK'
        );
    },
);

sub run_tests {
    SKIP: {
        if(!$test_opts{$driver}) {
            skip("$driver tests have been disabled", scalar @tests);
        }

        eval "require DBD:\:$driver; 1;"
            or die "$@\n";
    
        my $dsn = dsn($driver);

        $dbh = DBIx::Transaction->connect(
            $dsn, $test_opts{"$driver\_user"}, $test_opts{"$driver\_pass"},
            { AutoCommit => 0, RaiseError => 0, PrintError => 1 }
        )
            or die qq{failed to connect using dsn "$dsn": }, DBI->errstr;

        $migration = DBIx::Migration::Directories->new(
            dbh                     =>  $dbh,
            base                    =>  "t/tetc",
            schema                  =>  'TestSchema',
        );
            
        $migration2 = DBIx::Migration::Directories->new(
            dbh                     =>  $dbh,
            dir                     =>  "t/tetc/TestSchema2",
            schema                  =>  'TestSchema2',
        );
        
        diag('Got a ' . ref($migration) . ' object');
            
        if($migration->{current_version} || $migration2->{current_version}) {
            $dbh->disconnect();
            skip(
                "$driver database already has test schema installed.",
                scalar @tests
            );
        }

        foreach my $test (@tests) {
            $test->();
        }    

        $dbh->disconnect();
    }
}

plan tests => scalar(@tests) * scalar(@drivers);

foreach $driver (@drivers) {
    run_tests();
}
exit;
