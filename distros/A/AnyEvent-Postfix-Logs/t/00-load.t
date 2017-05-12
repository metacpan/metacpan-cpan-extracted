#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyEvent::Postfix::Logs' );
}

diag( "Testing AnyEvent::Postfix::Logs $AnyEvent::Postfix::Logs::VERSION, Perl $], $^X" );
