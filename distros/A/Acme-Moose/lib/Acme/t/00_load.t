#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Moose' ) || print "Bail out!
";
}

diag( "Testing Moose $Orignal::VERSION, Perl $], $^X" );
