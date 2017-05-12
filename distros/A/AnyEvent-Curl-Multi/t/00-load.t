#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyEvent::Curl::Multi' ) || print "Bail out!
";
}

diag( "Testing AnyEvent::Curl::Multi $AnyEvent::Curl::Multi::VERSION, Perl $], $^X" );
