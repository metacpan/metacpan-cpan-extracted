#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyEvent::Sway' ) || print "Bail out!
";
}

diag( "Testing AnyEvent::Sway $AnyEvent::Sway::VERSION, Perl $], $^X" );
