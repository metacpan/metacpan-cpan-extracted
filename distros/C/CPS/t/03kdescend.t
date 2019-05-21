#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use CPS qw( kdescendd kdescendb );

my $ret;

$ret = "";
kdescendd(
   [ [ [ 1, 2 ], 3, [ 4 ] ], 5 ],
   sub {
      my ( $i, $kmore ) = @_;
      return $kmore->( @$i ) if ref $i;

      $ret .= $i;
      $kmore->()
   },
   sub { }
);

is( $ret, "12345", 'kdescendd sync $ret' );

$ret = "";
kdescendb(
   [ [ [ 1, 2 ], 3, [ 4 ] ], 5 ],
   sub {
      my ( $i, $kmore ) = @_;
      return $kmore->( @$i ) if ref $i;

      $ret .= $i;
      $kmore->()
   },
   sub { }
);

is( $ret, "53124", 'kdescendb sync $ret' );

done_testing;
