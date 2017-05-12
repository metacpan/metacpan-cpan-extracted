#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'CLI::Startup' ) || print "Bail out!
";
}

diag( "Testing CLI::Startup $CLI::Startup::VERSION, Perl $], $^X" );
