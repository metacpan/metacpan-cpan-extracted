#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::VersionedDDL' );
}

diag( "Testing DBIx::VersionedDDL $DBIx::VersionedDDL::VERSION, Perl $], $^X" );
