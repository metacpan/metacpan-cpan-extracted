#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::SMS' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::SMS $Dancer::Plugin::SMS::VERSION, Perl $], $^X" );
