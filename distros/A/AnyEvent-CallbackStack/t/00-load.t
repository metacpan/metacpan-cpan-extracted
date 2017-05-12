#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyEvent::CallbackStack' ) || print "Bail out!
";
}

diag( "Testing AnyEvent::CallbackStack $AnyEvent::CallbackStack::VERSION, Perl $], $^X" );
