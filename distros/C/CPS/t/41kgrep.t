#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;

use CPS::Functional qw( kgrep );

my @nums;

kgrep(
   [ 1, 2, 3, 4 ],
   sub {
      my ( $item, $k ) = @_;
      $k->( $item % 2 == 0 );
   },
   sub {
      @nums = @_;
   },
);

is_deeply( \@nums, [ 2, 4 ], 'kgrep sync - @nums' );

@nums = ();
