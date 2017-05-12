#!/usr/bin/perl

use strict;
use warnings;

use Brick;
use Benchmark;

my $brick = Brick->new();
my $bucket = $brick->create_bucket();

# make some bricks to work with
for ( 0..118 ) {
   my $coderef = $bucket->add_to_bucket({
       name => $_,
       code => sub { $_[0]->{something} eq $_ ? 1 : () },
   } );
}

for my $start ( 0..99 ) {

	print "Run %3d", $start;
	
	timethis( 20, sub {
                 my $coderef = $bucket->__compose_pass_or_stop(
                     $bucket->get_brick_by_name($start),
                     $bucket->get_brick_by_name($start++),
                     $bucket->get_brick_by_name($start+1),
                     $bucket->get_brick_by_name($start+2),
                     $bucket->get_brick_by_name($start+3),
                 );
             }
         );
}