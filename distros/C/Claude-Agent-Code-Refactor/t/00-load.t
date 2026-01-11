#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Claude::Agent::Code::Refactor' ) || print "Bail out!\n";
    use_ok( 'Claude::Agent::Code::Refactor::Options' ) || print "Bail out!\n";
    use_ok( 'Claude::Agent::Code::Refactor::Result' ) || print "Bail out!\n";
}

diag( "Testing Claude::Agent::Code::Refactor $Claude::Agent::Code::Refactor::VERSION, Perl $], $^X" );
