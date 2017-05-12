#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;

use CPS qw( kpareach );

my $result = "";

kpareach(
   [ "A", "B" ],
   sub { $result .= shift; shift->() },
   sub { $result .= "C"; }
);

is( $result, "ABC", 'kpareach sync' );

my @pokes;

$result = "";
kpareach(
   [ "A", "B" ],
   sub { $result .= shift; push @pokes, shift },
   sub { $result .= "C"; }
);

is( $result, "AB", 'kpareach async before pokes' );
is( scalar @pokes, 2, '2 pokes queued' );

(shift @pokes)->();

is( $result, "AB", 'kpareach async still unfinished after 1 poke' );

(shift @pokes)->();

is( $result, "ABC", 'kpareach async now finished after 2 pokes' );
