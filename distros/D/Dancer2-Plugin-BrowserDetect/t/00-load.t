use strict;
use warnings;

use Test::More tests => 1;                      # last test to print


BEGIN {
    use_ok( 'Dancer2::Plugin::BrowserDetect' ) || print "Bail out";
}

diag( "Testing Dancer2::Plugin::Browser $Dancer2::Plugin::BrowserDetect::VERSION, Perl $], $^X" );
