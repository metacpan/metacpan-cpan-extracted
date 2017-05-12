#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;

use CPS qw( kseq );

my $result = "";

kseq(
   sub { $result .= "A"; shift->() },
   sub { $result .= "B"; shift->() },
   sub { $result .= "C"; }
);

is( $result, "ABC", 'kseq sync' );

my @pokes;

$result = "";
kseq(
   sub { $result .= "A"; push @pokes, shift },
   sub { $result .= "B"; push @pokes, shift },
   sub { $result .= "C"; }
);

is( $result, "A", 'kseq async before pokes' );
is( scalar @pokes, 1, '1 poke queued' );

(shift @pokes)->();

is( $result, "AB", 'kseq async still unfinished after 1 poke' );

(shift @pokes)->();

is( $result, "ABC", 'kseq async now finished after 2 pokes' );
