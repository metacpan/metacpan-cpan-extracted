#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

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
