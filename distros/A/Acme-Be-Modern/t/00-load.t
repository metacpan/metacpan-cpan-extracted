#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::Be::Modern' ) || print "Bail out!
";
}

diag( "Testing Acme::Be::Modern $Acme::Be::Modern::VERSION, Perl $], $^X" );
