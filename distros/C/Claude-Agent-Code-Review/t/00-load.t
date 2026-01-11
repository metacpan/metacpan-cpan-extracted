#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Claude::Agent::Code::Review' ) || print "Bail out!\n";
}

diag( "Testing Claude::Agent::Code::Review $Claude::Agent::Code::Review::VERSION, Perl $], $^X" );
