#!perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
## no critic (ControlStructures::ProhibitPostfixControls)

use strict;
use warnings;

use English qw( -no_match_vars );    # Avoids regex performance
local $OUTPUT_AUTOFLUSH = 1;

use utf8;
use Test2::V0;
set_encoding('utf8');

use Const::Fast;
use Try::Tiny;

# Activate for testing
# use Log::Any::Adapter ('Stdout', log_level => 'debug' );

use Database::Temp ();

skip_all('Skip testing with PostgreSQL; Not available')
  if ( !Database::Temp->is_available( driver => 'Pg' ) );

subtest 'Pg: Shortest example' => sub {
    my $db  = Database::Temp->new( driver => 'Pg', );
    my $dbh = DBI->connect( $db->connection_info );

    {
        my $rows = $dbh->selectall_arrayref('SELECT 1, 1+2');
        is( $rows->[0], [ 1, 3 ], 'Return simplest query correctly' );
    }

    done_testing;
};

subtest 'Pg: Database name' => sub {
    my $db = Database::Temp->new( driver => 'Pg', );
    isa_ok( $db, ['Database::Temp::DB'], 'Temp database is Database::Temp::DB' );
    can_ok( $db, [qw( connection_info )], 'Temp database can connection_info()' );
    my $dbh = DBI->connect( $db->connection_info );

    {
        # DB name
        my $name = $db->name;
        my $rows = $dbh->selectall_arrayref( <<"EOT" );
    SELECT datname FROM pg_catalog.pg_database
    WHERE datname = '$name'
    ORDER BY datname
EOT
        is( $rows->[0], [$name], 'Return database name correctly' );
    }

    done_testing;
};

use UUID::Tiny qw{ create_uuid_as_string UUID_V1 };
const my $SHORT_UUID_LEN => 6;

sub short_uuid {
    return ( substr create_uuid_as_string(UUID_V1), 0, $SHORT_UUID_LEN );
}

subtest 'Pg: Test db gets a new schema' => sub {
    {
        my $schema_name = "test_${\(short_uuid())}";
        my $DDL         = <<'EOF';
    CREATE TABLE test_table (
        id INTEGER
        , name VARCHAR(20)
        , age INT
        );
    CREATE SEQUENCE IF NOT EXISTS "seq_master"
        INCREMENT BY 1 MINVALUE 1 NO MAXVALUE START WITH 2 CACHE 1 NO CYCLE;
    COMMENT ON SEQUENCE "seq_master" IS 'Every op has a unique seq.';
EOF

        my $db = Database::Temp->new(
            driver  => 'Pg',
            cleanup => 1,
            args    => {},

            # init => sub {
            init => <<"EOT",
    CREATE SCHEMA $schema_name;
    SET search_path TO $schema_name;
    $DDL
EOT
        );
        diag "Test database ${\($db->driver)}) ${\($db->name)} created.\n";

        my $dbh = DBI->connect( $db->connection_info );
        my $r   = $dbh->do("INSERT INTO $schema_name.test_table VALUES(1, 'My Name', 33)");
        $r = $dbh->do("INSERT INTO $schema_name.test_table VALUES(2, 'My Other Name', 43)");
        my $rows = $dbh->selectall_arrayref( "SELECT id, name, age FROM $schema_name.test_table ORDER BY id", );
        is( $rows->[0]->[1], 'My Name' );
    }

    done_testing;
};

subtest 'Pg: Test db gets created and removed' => sub {
    my $name;
    my @connection_info;
    {
        my $db = Database::Temp->new( driver => 'Pg', );
        diag 'Test database (' . $db->driver . ') ' . $db->name . " created.\n";
        $name = $db->name;
        my $rows = DBI->connect( $db->connection_info )->selectall_arrayref( <<"EOT" );
    SELECT datname FROM pg_catalog.pg_database
    WHERE datname = '$name'
    ORDER BY datname
EOT
        is( $rows->[0]->[0], $name );
        @connection_info = $db->connection_info;
        my $dbh = DBI->connect(@connection_info);
        isnt( $dbh, undef, 'Connection established' );
    }

    # DB id dropped when $db drops out of scope.
    like( dies { DBI->connect(@connection_info) }, qr/FATAL/msx, 'Cannot establish connection after database is dropped' );

    done_testing;
};

done_testing;
