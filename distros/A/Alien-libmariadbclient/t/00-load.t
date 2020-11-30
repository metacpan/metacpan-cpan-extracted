#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Alien::libmariadbclient' ) || print "Bail out!\n";
}

diag( "Testing Alien::libmariadbclient $Alien::libmariadbclient, Perl $], $^X" );
