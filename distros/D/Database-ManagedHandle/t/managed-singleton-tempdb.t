#!perl

use strict;
use warnings;

use utf8;
use Test2::V0;
set_encoding('utf8');

use Scalar::Util 'refaddr';

# Activate for testing
# use Log::Any::Adapter ('Stdout', log_level => 'debug' );

use Test::Database::Temp;
use Database::Temp;

my @test_dbs;

BEGIN {
    diag 'Create temp databases';

    # We use only SQLite drivers because we can be certain that SQLite driver is present.
    # The other tests test against all available drivers.
    my @drivers = Test::Database::Temp->available_drivers( drivers => [qw( SQLite SQLite )] );
    foreach (@drivers) {
        my $test_db = Database::Temp->new( driver => $_, );
        diag 'Test database (' . $test_db->driver . ') ' . $test_db->name . " created.\n";
        push @test_dbs, $test_db;
    }
    {

        package Database::ManagedHandleConfigTestTempDB;
        use strict;
        use warnings;

        use Moo;

        has config => (
            is      => 'ro',
            default => sub {
                my %cfg = ( 'default' => $test_dbs[0]->name(), );
                foreach (@test_dbs) {
                    my $name = $_->name();
                    my @info = $_->connection_info();
                    my %c;
                    @c{ 'dsn', 'username', 'password', 'attr' } = @info;
                    $cfg{'databases'}->{$name} = \%c;
                }
                return \%cfg;
            },
        );

        1;
    }
    ## no critic (Variables::RequireLocalizedPunctuationVars)
    $ENV{DATABASE_MANAGED_HANDLE_CONFIG} = 'Database::ManagedHandleConfigTestTempDB';

    use Database::ManagedHandle;
}

subtest 'Two local copies of ManagedHandle' => sub {
    my $mh1     = Database::ManagedHandle->instance;
    my $dbh1    = $mh1->dbh( $test_dbs[0]->name );
    my $ary_ref = $dbh1->selectall_arrayref('SELECT 1');
    is( $ary_ref->[0]->[0], 1, 'SELECT 1' );

    my $mh2    = Database::ManagedHandle->instance();
    my $dbh2   = $mh2->dbh( $test_dbs[1]->name );
    my $dbh1_1 = $mh2->dbh( $test_dbs[0]->name );
    my $dbh2_1 = $mh1->dbh( $test_dbs[1]->name );

    ok( refaddr($mh1) == refaddr($mh2), 'Managed handles are the same object' );

    ok( refaddr($dbh1) != refaddr($dbh2),     'Database handles are not the same object' );
    ok( refaddr($dbh1_1) != refaddr($dbh2_1), 'Database handles are not the same object' );
    ok( refaddr($dbh1) == refaddr($dbh1_1),   'Database handles are the same object' );
    ok( refaddr($dbh2) == refaddr($dbh2_1),   'Database handles are the same object' );

    done_testing;
};

done_testing;
