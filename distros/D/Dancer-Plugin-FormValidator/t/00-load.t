use strict;
use warnings;

use Test::More tests => 1;                      # last test to print


BEGIN {
    use_ok( 'Dancer::Plugin::FormValidator' ) || print "Bail out";
}

diag( "Testing Dancer::Plugin::FormValidator $Dancer::Plugin::FormValidator::VERSION, Perl $], $^X" );
