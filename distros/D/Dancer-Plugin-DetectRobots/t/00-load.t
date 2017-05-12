use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

BEGIN {
    use_ok( 'Dancer::Plugin::DetectRobots' ) || print "Bail out";
}

diag( "Testing Dancer::Plugin::DetectRobots $Dancer::Plugin::DetectRobots::VERSION, Perl $], $^X" );
