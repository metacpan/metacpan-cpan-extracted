#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::ActionRole::NotCacheableHeaders' ) || print "Bail out!
";
}

diag( "Testing Catalyst::ActionRole::NotCacheableHeaders $Catalyst::ActionRole::NotCacheableHeaders::VERSION, Perl $], $^X" );
