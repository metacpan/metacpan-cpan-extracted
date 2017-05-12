#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer2::Plugin::Auth::Extensible' ) || print "Bail out!
";
}

diag( "Testing Dancer2::Plugin::Auth::Extensible $Dancer2::Plugin::Auth::Extensible::VERSION, Perl $], $^X" );
