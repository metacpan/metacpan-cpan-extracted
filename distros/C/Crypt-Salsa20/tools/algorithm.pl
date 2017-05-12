#! /usr/bin/perl
#---------------------------------------------------------------------
# tools/algorithm.pl
#
# Copyright 2013 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Generate code for the salsa20_wordtobyte algorithm in Perl
#
# This is based on salsa20-regs.c version 20051118 by D. J. Bernstein,
# which is in the public domain.
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.010;

use autodie ':io';

my @round = (
#x[ 4] = XOR(x[ 4],ROTATE(PLUS(x[ 0],x[12]), 7));
  [ 4,          4,                0,   12,   7],
  [ 8,          8,                4,    0,   9],
  [12,         12,                8,    4,  13],
  [ 0,          0,               12,    8,  18],
  [ 9,          9,                5,    1,   7],
  [13,         13,                9,    5,   9],
  [ 1,          1,               13,    9,  13],
  [ 5,          5,                1,   13,  18],
  [14,         14,               10,    6,   7],
  [ 2,          2,               14,   10,   9],
  [ 6,          6,                2,   14,  13],
  [10,         10,                6,    2,  18],
  [ 3,          3,               15,   11,   7],
  [ 7,          7,                3,   15,   9],
  [11,         11,                7,    3,  13],
  [15,         15,               11,    7,  18],
  [ 1,          1,                0,    3,   7],
  [ 2,          2,                1,    0,   9],
  [ 3,          3,                2,    1,  13],
  [ 0,          0,                3,    2,  18],
  [ 6,          6,                5,    4,   7],
  [ 7,          7,                6,    5,   9],
  [ 4,          4,                7,    6,  13],
  [ 5,          5,                4,    7,  18],
  [11,         11,               10,    9,   7],
  [ 8,          8,               11,   10,   9],
  [ 9,          9,                8,   11,  13],
  [10,         10,                9,    8,  18],
  [12,         12,               15,   14,   7],
  [13,         13,               12,   15,   9],
  [14,         14,               13,   12,  13],
  [15,         15,               14,   13,  18],
);# 1           2                 3     4    5
#x[ 4] = XOR(x[ 4],ROTATE(PLUS(x[ 0],x[12]), 7));

print <<'';
        # BEGIN generated code from tools/algorithm.pl

for my $n (0 .. 15) {
  say "        \$x$n = \$input$n;";
}

print <<'';
        for (1 .. $loops) {
          if (IS32BIT) {
            # "use integer" must be used very carefully here.
            # It causes the shift operators to use sign extension,
            # which we don't want.  So the additions are under
            # "use integer", but the shifts are not.
            # The Perl optimizer isn't smart enough to know that
            # "& 0xffffffff" is a no-op with 32-bit integer arithmetic,
            # and the unnecessary ops slow things down.

for my $r (@round) {
  die unless $r->[0] == $r->[1];
  printf <<'', @$r;
            { use integer; $x = $x%3$d + $x%4$d };
            $x%1$d ^= ($x << %5$d) | ($x >> (32 - %5$d));

}

print <<'';
          } else { # 64-bit integers
            use integer;

for my $r (@round) {
  die unless $r->[0] == $r->[1];
  printf <<'', @$r;
            $x = ($x%3$d + $x%4$d) & 0xffffffff;
            $x%1$d ^= (($x << %5$d) | ($x >> (32 - %5$d))) & 0xffffffff;

}

print <<'';
          }
        }
        { use integer;
          $cryptblock = pack('V16',


for my $n (0 .. 15) {
  say "            \$x$n + \$input$n,";
}
print <<'';
          );
        }
        # END generated code from tools/algorithm.pl

__END__
