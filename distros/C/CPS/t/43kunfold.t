#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use CPS::Functional qw( kunfold );

my @nums;

kunfold(
   1,
   sub {
      my ( $n, $kmore, $kdone ) = @_; 

      if( $n < 5 ) {
         $kmore->( $n + 1, $n );
      }
      else {
         $kdone->();
      }
   },
   sub {
      @nums = @_;
   }
);

is_deeply( \@nums, [ 1, 2, 3, 4 ], 'kunfold sync - @nums' );

done_testing;
