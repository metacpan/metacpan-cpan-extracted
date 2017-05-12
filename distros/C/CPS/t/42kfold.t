#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

use CPS::Functional qw( kfoldl kfoldr );

my $ret;

kfoldl(
   [ 1, 2, 3 ],
   sub {
      my ( $left, $right, $k ) = @_;
      $k->( "($left+$right)" );
   },
   sub {
      $ret = shift;
   },
);

is( $ret, "((1+2)+3)", 'kfoldl sync - @nums' );

kfoldr(
   [ 1, 2, 3 ],
   sub {
      my ( $left, $right, $k ) = @_;
      $k->( "($left+$right)" );
   },
   sub {
      $ret = shift;
   },
);

is( $ret, "(1+(2+3))", 'kfoldr sync - @nums' );
