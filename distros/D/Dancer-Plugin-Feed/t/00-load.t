use strict;
use warnings;

use Test::More tests => 1;                      # last test to print


BEGIN {
    use_ok( 'Dancer::Plugin::Feed' ) || print "Bail out";
}

diag( "Testing Dancer::Plugin::Feed $Dancer::Plugin::Feed::VERSION, Perl $], $^X" );
