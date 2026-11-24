#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Backstory' ) || print "Bail out!\n";
}

diag( "Testing Backstory $Backstory::VERSION, Perl $], $^X" );
