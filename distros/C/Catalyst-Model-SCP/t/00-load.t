#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Catalyst::Model::SCP' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Model::SCP $Catalyst::Model::SCP::VERSION, Perl $], $^X" );
