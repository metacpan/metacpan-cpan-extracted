#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'BackPAN::Version::Discover' ) || print "Bail out!
";
}

diag( "Testing BackPAN::Version::Discover $BackPAN::Version::Discover::VERSION, Perl $], $^X" );
