#!perl -T

use Test::More tests => 1;

BEGIN {
    ok( -e "bin/jawk", "bin/jawk exists" );
    #ok( -x "bin/jawk", "bin/jawk is executable" );
}

#diag( "Testing App::Jawk $App::Jawk::VERSION, Perl $], $^X" );
1;
