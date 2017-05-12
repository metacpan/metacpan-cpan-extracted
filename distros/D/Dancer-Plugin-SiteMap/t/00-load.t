#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::SiteMap' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::SiteMap $Dancer::Plugin::SiteMap::VERSION, Perl $], $^X" );
