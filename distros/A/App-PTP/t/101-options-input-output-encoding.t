#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use Test::More tests => 4;

{
  my $utf8_to_utf8 = ptp([], 'encoding_utf8.txt');
  ok($utf8_to_utf8 eq "hélô\nœ¡f\n");
} {
  my $iso_to_utf8 =
    ptp([qw(--in-encoding ISO-8859-15)], 'encoding_iso_8859_15.txt');
  ok($iso_to_utf8 eq "hélô\nœ¡f\n");
} {
  my $iso_to_iso =
    ptp([qw(--in-encoding ISO-8859-15 --out-encoding ISO-8859-15)],
        'encoding_iso_8859_15.txt');
  ok($iso_to_iso eq "h\x{E9}l\x{F4}\n\x{BD}\x{A1}f\n");
} {
  my $utf8_to_iso =
    ptp([qw(--out-encoding ISO-8859-15)],
        'encoding_utf8.txt');
  ok($utf8_to_iso eq "h\x{E9}l\x{F4}\n\x{BD}\x{A1}f\n");
}
