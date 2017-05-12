#!/usr/bin/perl -w

use strict;

use Test::More tests => 6;

use CPS qw( kpar );

my $result = "";

kpar(
   sub { $result .= "A"; shift->() },
   sub { $result .= "B"; shift->() },
   sub { $result .= "C"; }
);

is( $result, "ABC", 'kpar sync' );

my @pokes;

$result = "";
kpar(
   sub { $result .= "A"; push @pokes, shift },
   sub { $result .= "B"; push @pokes, shift },
   sub { $result .= "C"; }
);

is( $result, "AB", 'kpar async before pokes' );
is( scalar @pokes, 2, '2 pokes queued' );

(shift @pokes)->();

is( $result, "AB", 'kpar async still unfinished after 1 poke' );

(shift @pokes)->();

is( $result, "ABC", 'kpar async now finished after 2 pokes' );

my @result;
kpar(
   sub {
      shift->( 1, 2, 3 );
   },
   sub {
      push @result, @_;
   }
);

is_deeply( \@result, [], 'kpar clears @_' );
