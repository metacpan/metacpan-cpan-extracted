#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

use CPS qw( kforeach );

my @nums;

kforeach(
   [ 1, 2, 3 ],
   sub {
      my ( $item, $knext ) = @_;

      push @nums, $item;

      $knext->();
   },
   sub {
      push @nums, "finished";
   },
);

is_deeply( \@nums, [ 1, 2, 3, "finished" ], 'kforeach sync - @nums' );

@nums = ();

kforeach(
   [ 4, 5, 6, 7 ],
   sub {
      my ( $item, $knext, $klast ) = @_;

      goto &$klast if $item == 6;
      push @nums, $item;

      $knext->();
   },
   sub {
      push @nums, "finished";
   },
);

is_deeply( \@nums, [ 4, 5, "finished" ], 'kforeach sync - @nums' );
