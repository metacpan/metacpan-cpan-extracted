#!perl

use strict;
use warnings;
use lib "t/tlib";
use Test::More;
use Test::MigrationTest;
use DBIx::Transaction;
use DBIx::Migration::Directories;
use Data::Dumper;

our($driver, $migration, $sth, $dbh, $rv, $row, $rows, @sql, $log);

my @tests = (
    sub { is($migration->full_migrate(), 1, "$driver driver: Execute migration"); },
    sub {
        $dbh->begin_work;
        $sth = $dbh->prepare("SELECT * FROM migration_schema_version");
        $sth->execute();
        $rows = $sth->fetchall_arrayref();
        $sth->finish;
        is(scalar @$rows, 1, "$driver driver: Row in version table");
    },
    sub {
        ok(
            $rows->[0]->[1] == $DBIx::Migration::Directories::SCHEMA_VERSION,
            "$driver driver: Correct version"
        );
        $dbh->commit;
    },
    sub {
        $dbh->begin_work;
        $sth = $dbh->prepare(q{
          SELECT * FROM migration_schema_log ORDER BY event_time, new_version
        });
        $sth->execute();
        $rows = $sth->fetchall_arrayref({});
        diag(Data::Dumper->Dump([$rows]));
        is(scalar @$rows, 3, "$driver driver: Rows in log table");
        $row = $rows->[2];
        $sth->finish();
        $dbh->commit;
    },
    sub {
        is(
            $row->{schema_name},
            'DBIx-Migration-Directories',
            "$driver driver: Correct schema name"
        );
    },
    sub {
        is($row->{old_version} + 0, 0.02, "$driver driver: Correct old version");
    },
    sub {
        is(
            $row->{new_version} + 0, $DBIx::Migration::Directories::SCHEMA_VERSION,
            "$driver driver: Correct new version"
        );
    },
    sub {
        $log = $migration->schema_version_log;
        is(scalar @$log, 3, "$driver driver: schema_version_log has three entries for us.");
        $row = $log->[2];
    },
    sub {
        is($row->{old_version} + 0, 0.02, "$driver driver: Correct old version");
    },
    sub {
        is(
            $row->{new_version} + 0, $DBIx::Migration::Directories::SCHEMA_VERSION,
            "$driver driver: Correct new version"
        );
    },
    sub {
        diag('Expect a table already exists error here.');
        my $s = $migration->{schema};
        $migration->{schema} = 'NotASchema';
        ok(
            !$migration->full_migrate(
                current_version => 0,
                common_dir      =>  "schema/_common",
                dir             =>  "schema/$driver",
                desired_version => $DBIx::Migration::Directories::SCHEMA_VERSION

            ),
            "Can't migrate already migrated schema"
        );
        $migration->{schema} = $s;
    },
    sub {
        is(
            $migration->get_current_version + 0,
            $DBIx::Migration::Directories::SCHEMA_VERSION + 0,
            "$driver driver: We agree with current version number"
        );
    },
    sub {
        is(
            $migration->set_desired_version + 0,
            $DBIx::Migration::Directories::SCHEMA_VERSION + 0,
            "$driver driver: We are at the best version number"
        );
    },
    sub {
        SKIP: {
            if($driver eq 'mysql') {
               skip("MySQL can't garuntee transactions", 1);
            }
            
            diag('Expect errors here.');
            my $rv;
            my $s = $migration->{schema};
            $migration->{schema} = 'FooSchema';
            if($migration->full_delete_schema) {
                $rv = 0;
            } else {
                $rv = 1;
            }
            $migration->{schema} = $s;
            ok($rv, "Deleting migration schema fails unless we know it's name");
        };
    },
    sub {
        is(
            $migration->get_current_version + 0,
            $DBIx::Migration::Directories::SCHEMA_VERSION + 0,
            "$driver driver: We agree with current version number"
        );
    },
    sub {
        is(
            $migration->set_desired_version + 0,
            $DBIx::Migration::Directories::SCHEMA_VERSION + 0,
            "$driver driver: We are at the best version number"
        );
    },
    sub {
        my $rv = $migration->schemas;
        is(scalar keys %$rv, 1, "$driver driver: We have exactly one schema installed");
    },
    sub {
        is(
            $migration->full_delete_schema,
            1,
            "$driver driver: Backout queries complete"
        );
    },
    sub {
        ok(
            !$migration->delete_schema_record,
            "$driver driver: Can't delete a schema record when migration tables don't exist"
        );
    },
    sub {
        $dbh->begin_work;
        $dbh->{PrintError} = 0;
        $sth = $dbh->prepare("SELECT * FROM migration_schema_version");
        $rv = $sth->execute();
        $sth->finish();
        is($rv, undef, "$driver driver: Table gone");
        $dbh->{PrintError} = 1;
        $dbh->rollback;
    },
    sub {
        my $rv = $migration->schemas;
        ok(
            !$rv,
            "$driver driver: Can't get schema list without a migration schema"
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

        $dbh->begin_work();
        $dbh->{PrintError} = 0;
        $sth = $dbh->prepare("SELECT * FROM migration_schema_version");
        $rv = $sth->execute();
        $sth->finish();
        $dbh->rollback();
        
        if(defined $rv) {
            $dbh->disconnect();
            skip("$driver already has migration schema", scalar @tests);
            return;
        }

        $migration = DBIx::Migration::Directories->new(
            dbh                     =>  $dbh,
            dir                     =>  "schema/$driver",
            common_dir              =>  "schema/_common",
            schema                  =>  'DBIx-Migration-Directories',
            desired_version_from    =>  'DBIx::Migration::Directories',
        );

        diag('Got a ' . ref($migration) . ' object');
        
        $dbh->{PrintError} = 1;

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
