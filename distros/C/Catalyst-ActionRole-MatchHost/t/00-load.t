#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::ActionRole::MatchHost' );
}

diag( "Testing Catalyst::ActionRole::MatchHost $Catalyst::ActionRole::MatchHost::VERSION, Perl $], $^X" );
