#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::Compress::WithExclusions' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Plugin::Compress::WithExclusions $Catalyst::Plugin::Compress::WithExclusions::VERSION, Perl $], $^X" );
