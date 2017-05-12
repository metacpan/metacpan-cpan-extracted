use strict;
use warnings;

use Test::More tests => 1;                      # last test to print


BEGIN {
    use_ok( 'Dancer::Plugin::Browser' ) || print "Bail out";
}

diag( "Testing Dancer::Plugin::Browser $Dancer::Plugin::Browser::VERSION, Perl $], $^X" );
