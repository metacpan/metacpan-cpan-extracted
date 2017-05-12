#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;

use CPS qw( kloop );

my $poke;

my @nums;

my $num = 1;

kloop(
   sub {
      my ( $knext, $klast ) = @_;

      push @nums, $num;
      $num++;

      $poke = ( $num == 3 ) ? $klast : $knext;
   },
   sub {
      push @nums, "finished";
   },
);

is_deeply( \@nums, [ 1 ], 'kloop async - @nums initially' );
$poke->();
is_deeply( \@nums, [ 1, 2 ], 'kloop async - @nums after first poke' );
$poke->();
is_deeply( \@nums, [ 1, 2, "finished" ], 'kloop async - @nums after second poke' );

@nums = ();

our $nested = 0;

kloop(
   sub {
      my ( $knext, $klast ) = @_;

      is( $nested, 0, "kloop sync call does not nest for $num" );

      local $nested = 1;

      push @nums, $num;
      $num++;

      ( ( $num == 5 ) ? $klast : $knext )->();
   },
   sub {
      push @nums, "finished";
   },
);

is_deeply( \@nums, [ 3, 4, "finished" ], 'kloop sync - @nums initially' );

my @result;
kloop(
   sub {
      my ( $knext, $klast ) = @_;
      $klast->( 1, 2, 3 );
   },
   sub {
      push @result, @_;
   }
);

is_deeply( \@result, [], 'kloop clears @_ in $klast' );
