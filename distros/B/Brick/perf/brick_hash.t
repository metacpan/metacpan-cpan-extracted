#!/usr/bin/perl

use strict;
use warnings;

use Brick;
use Benchmark;

my $brick  = Brick->new();
my $bucket = $brick->create_bucket();

my %cache = ();

# make some bricks to work with
for ( 0..118 ) {
   my $coderef = $bucket->add_to_bucket({
       name => $_,
       code => sub { $_[0]->{something} eq $_ ? 1 : () },
   } );
   
   $cache{ $_ } = $coderef;
}

for my $start ( 0..99 ) {

	printf "Run %3d: ", $start;
	
	timethis( 200, sub {
                 my $coderef = $bucket->__compose_pass_or_stop(
                     map { $cache{ $_ } } $start .. $start + 3
                 );
             }
         );
}