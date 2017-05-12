#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::ActionRole::CheckTrailingSlash' );
}

diag( "Testing Catalyst::ActionRole::CheckTrailingSlash $Catalyst::ActionRole::CheckTrailingSlash::VERSION, Perl $], $^X" );
