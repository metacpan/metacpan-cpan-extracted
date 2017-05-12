#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer2::Plugin::HTTP::Auth::Extensible' ) || print "Bail out!
";
}

diag( "Testing Dancer2::Plugin::HTTP::Auth::Extensible $Dancer2::Plugin::HTTP::Auth::Extensible::VERSION, Perl $], $^X" );
