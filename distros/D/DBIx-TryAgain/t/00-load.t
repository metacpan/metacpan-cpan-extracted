#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::TryAgain' ) || print "Bail out!\n";
}

diag( "Testing DBIx::TryAgain $DBI::TryAgain::VERSION, Perl $], $^X" );
