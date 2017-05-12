#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyEvent::Handle::Writer' ) || print "Bail out!
";
}

diag( "Testing AnyEvent::Handle::Writer $AnyEvent::Handle::Writer::VERSION, Perl $], $^X" );
