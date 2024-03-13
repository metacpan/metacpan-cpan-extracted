#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.10';

plan tests => 1;

BEGIN {
    use_ok( 'Config::JSON::Enhanced' ) || print "Bail out!\n";
}

diag( "Testing Config::JSON::Enhanced $Config::JSON::Enhanced::VERSION, Perl $], $^X" );
