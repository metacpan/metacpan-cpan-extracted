use strict;
use warnings;

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::TestOnTap' ) || print "Bail out!\n";
}

diag( "Testing App::TestOnTap $App::TestOnTap::VERSION, Perl $], $^X" );
