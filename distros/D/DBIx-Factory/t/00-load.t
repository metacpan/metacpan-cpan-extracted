#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Factory' ) || print "Bail out!
";
}

diag( "Testing DBIx::Factory $DBIx::Factory::VERSION, Perl $], $^X" );
