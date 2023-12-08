#!perl
## no critic (ControlStructures::ProhibitPostfixControls)

use strict;
use warnings;

use utf8;
use Test2::V0;
set_encoding('utf8');

use Const::Fast;
use Scalar::Util 'refaddr';

# Activate for testing
# use Log::Any::Adapter ('Stdout', log_level => 'debug' );

use Test::Database::Temp;
use Database::Temp;

my @test_dbs;

BEGIN {
    const my $DDL => <<'EOF';
    CREATE TABLE test_table (
        id INTEGER
        , driver VARCHAR(20)
        , created INTEGER
        , PRIMARY KEY (id)
        );
EOF

    const my $INSERT_SQL => <<'EOF';
  INSERT INTO test_table(id, driver, created) VALUES (1, '<DB_NAME>', 23);
EOF

    sub init_db {
        my ( $dbh, $name, $info, $driver ) = @_;

        # warn $name, $driver;
        $dbh->begin_work() if ( !$driver eq 'CSV' );
        foreach my $row ( split qr/;\s*/msx, $DDL ) {
            $dbh->do($row);
        }
        $dbh->commit       if ( !$driver eq 'CSV' );
        $dbh->begin_work() if ( !$driver eq 'CSV' );
        my $sql = $INSERT_SQL =~ s/<DB_NAME>/$driver/msxr;
        $dbh->do($sql);
        $dbh->commit if ( !$driver eq 'CSV' );
        return;
    }
    diag 'Create temp databases';
    my @drivers = Test::Database::Temp->available_drivers();
    foreach (@drivers) {
        my $test_db = Database::Temp->new(
            driver => $_,
            init   => sub {
                my ( $dbh, $name, $info, $driver ) = @_;
                init_db( $dbh, $name, $info, $driver );
            },
        );
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

for my $test_db (@test_dbs) {
    subtest "ManagedHandle returns correct database handle for ${ \$test_db->name } (${ \$test_db->driver })" => sub {
        my $mh1  = Database::ManagedHandle->instance;
        my $dbh1 = $mh1->dbh( $test_db->name );
        {
            my $dsn = $mh1->_config->{'databases'}->{ $test_db->name }->{'dsn'};
            is( $dsn, $test_db->{'dsn'}, 'DSNs match' );
            my ($dr) = $dsn =~ m/^dbi:([^:]+):/msx;
            my $ary_ref = $dbh1->selectall_arrayref('SELECT 1');
            is( $ary_ref->[0]->[0], 1, 'One matches' );
            $ary_ref = $dbh1->selectall_arrayref('SELECT id, driver FROM test_table');
            is( $ary_ref->[0]->[0], 1,   'Id matches' );
            is( $ary_ref->[0]->[1], $dr, 'Driver name matches' )
        }

        done_testing;
    };
}

# Undefine all Database::Temp objects explicitly to demolish
# the databases in good order, instead of doing it unmanaged
# during global destruct, when program dies.
@test_dbs = undef;

done_testing;
