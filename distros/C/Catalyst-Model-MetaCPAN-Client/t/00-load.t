#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Catalyst::Model::MetaCPAN::Client' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Model::MetaCPAN::Client $Catalyst::Model::MetaCPAN::Client::VERSION, Perl $], $^X" );
