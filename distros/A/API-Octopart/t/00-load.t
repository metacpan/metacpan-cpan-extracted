#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'API::Octopart' ) || print "Bail out!\n";
}

diag( "Testing API::Octopart $API::Octopart::VERSION, Perl $], $^X" );
