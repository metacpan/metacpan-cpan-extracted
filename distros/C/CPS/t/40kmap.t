#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use CPS::Functional qw( kmap );

my @nums;

kmap(
   [ 1, 2, 3 ],
   sub {
      my ( $item, $k ) = @_;
      $k->( $item * 2 );
   },
   sub {
      @nums = @_;
   },
);

is_deeply( \@nums, [ 2, 4, 6 ], 'kmap sync - @nums' );

@nums = ();

done_testing;
