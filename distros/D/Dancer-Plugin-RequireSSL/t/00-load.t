use strict;
use warnings;

use Test::More tests => 1;                      # last test to print


BEGIN {
    use_ok( 'Dancer::Plugin::RequireSSL' ) || print "Bail out";
}

diag( "Testing Dancer::Plugin::RequireSSL $Dancer::Plugin::RequireSSL::VERSION, Perl $], $^X" );
