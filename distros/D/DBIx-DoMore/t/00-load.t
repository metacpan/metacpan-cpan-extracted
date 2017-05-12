#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::DoMore' ) || print "Bail out!
";
}

diag( "Testing DBIx::DoMore $DBIx::DoMore::VERSION, Perl $], $^X" );
