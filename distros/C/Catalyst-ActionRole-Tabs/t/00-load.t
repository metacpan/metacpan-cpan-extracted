#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::ActionRole::Tabs' );
}

diag( "Testing Catalyst::ActionRole::Tabs $Catalyst::ActionRole::Tabs::VERSION, Perl $], $^X" );
