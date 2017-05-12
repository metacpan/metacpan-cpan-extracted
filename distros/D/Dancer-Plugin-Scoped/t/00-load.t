#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::Scoped' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::Scoped $Dancer::Plugin::Scoped::VERSION, Perl $], $^X" );
