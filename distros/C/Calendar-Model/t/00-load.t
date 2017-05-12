#!perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok( 'Calendar::Model' ) || print "Bail out!\n";
}

diag( "Testing Calendar::Model $Calendar::Model::VERSION, Perl $], $^X" );

my $cal = Calendar::Model->new;

isa_ok($cal, 'Calendar::Model');
