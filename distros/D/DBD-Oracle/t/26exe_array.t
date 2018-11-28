#!perl
# Completely new test for DBD::Oracle which came from DBD::ODBC
# Author: Martin J. Evans
#
# loads of execute_array and execute_for_fetch tests using DBI's methods

use strict;
use warnings;

use lib 't/lib';
use DBDOracleTestLib qw/ oracle_test_dsn db_handle /;

use Test::More;
use Data::Dumper;
require Test::NoWarnings;    # deliberately not calling import()

$| = 1;

use DBI qw(:sql_types);
use ExecuteArray;

$ENV{NLS_NCHAR} = 'US7ASCII';
$ENV{NLS_LANG}  = 'AMERICAN';

my $dbh = db_handle( { PrintError => 0 } )
  or plan skip_all => 'Unable to connect to Oracle';

my $ea = ExecuteArray->new( $dbh, 1 );    # set odbc_disable_array_operations
$dbh = $ea->dbh;

$ea->drop_table($dbh);
ok( $ea->create_table($dbh), 'create test table' ) or exit 1;

$ea->simple( $dbh, { array_context => 1, raise => 1 } );
$ea->simple( $dbh, { array_context => 0, raise => 1 } );
$ea->error( $dbh, { array_context => 1, raise => 1 } );
$ea->error( $dbh, { array_context => 0, raise => 1 } );
$ea->error( $dbh, { array_context => 1, raise => 0 } );
$ea->error( $dbh, { array_context => 0, raise => 0 } );

$ea->row_wise( $dbh, { array_context => 1, raise => 1 } );

$ea->update( $dbh, { array_context => 1, raise => 1 } );

for my $raise ( 0 .. 1 ) {
    for my $context ( 0 .. 1 ) {
        $ea->error(
            $dbh,
            {
                array_context => $context,
                raise         => $raise,
                notuplestatus => 1
            }
        );
    }
}

if ( $dbh && $ea ) {
    $ea->drop_table($dbh);
}

Test::NoWarnings::had_no_warnings();

done_testing;
