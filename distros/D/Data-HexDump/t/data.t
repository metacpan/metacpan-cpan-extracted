# -*- Mode: Perl -*-

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use Data::HexDump;

local $^W = 1;

print "1..10\n";
my $t = 1;
my $v = "f";

&Check ($t++, HexDump $v x 7,
	"          00 01 02 03 04 05 06 07 - " .
	"08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF\n\n" .
	"00000000  66 66 66 66 66 66 66      " .
	"                         fffffff\n");
&Check ($t++, HexDump $v x 8,
	"          00 01 02 03 04 05 06 07 - " .
	"08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF\n\n" .
	"00000000  66 66 66 66 66 66 66 66   " .
	"                         ffffffff\n");
&Check ($t++, HexDump $v x 9,
	"          00 01 02 03 04 05 06 07 - " .
	"08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF\n\n" .
	"00000000  66 66 66 66 66 66 66 66 - " .
	"66                       fffffffff\n");
&Check ($t++, HexDump $v x 15,
	"          00 01 02 03 04 05 06 07 - " .
	"08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF\n\n" .
	"00000000  66 66 66 66 66 66 66 66 - " .
	"66 66 66 66 66 66 66     fffffffffffffff\n");
&Check ($t++, HexDump $v x 16,
	"          00 01 02 03 04 05 06 07 - " .
	"08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF\n\n" .
	"00000000  66 66 66 66 66 66 66 66 - " .
	"66 66 66 66 66 66 66 66  ffffffffffffffff\n");

&Check ($t++, HexDump $v x 23,
	"          00 01 02 03 04 05 06 07 - " .
	"08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF\n\n" .
	"00000000  66 66 66 66 66 66 66 66 - " .
	"66 66 66 66 66 66 66 66  ffffffffffffffff\n" .
	"00000010  66 66 66 66 66 66 66      " .
	"                         fffffff\n");
&Check ($t++, HexDump $v x 24,
	"          00 01 02 03 04 05 06 07 - " .
	"08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF\n\n" .
	"00000000  66 66 66 66 66 66 66 66 - " .
	"66 66 66 66 66 66 66 66  ffffffffffffffff\n" .
	"00000010  66 66 66 66 66 66 66 66   " .
	"                         ffffffff\n");
&Check ($t++, HexDump $v x 25,
	"          00 01 02 03 04 05 06 07 - " .
	"08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF\n\n" .
	"00000000  66 66 66 66 66 66 66 66 - " .
	"66 66 66 66 66 66 66 66  ffffffffffffffff\n" .
	"00000010  66 66 66 66 66 66 66 66 - " .
	"66                       fffffffff\n");
&Check ($t++, HexDump $v x 31,
	"          00 01 02 03 04 05 06 07 - " .
	"08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF\n\n" .
	"00000000  66 66 66 66 66 66 66 66 - " .
	"66 66 66 66 66 66 66 66  ffffffffffffffff\n" .
	"00000010  66 66 66 66 66 66 66 66 - " .
	"66 66 66 66 66 66 66     fffffffffffffff\n");
&Check ($t++, HexDump $v x 32,
	"          00 01 02 03 04 05 06 07 - " .
	"08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF\n\n" .
	"00000000  66 66 66 66 66 66 66 66 - " .
	"66 66 66 66 66 66 66 66  ffffffffffffffff\n" .
	"00000010  66 66 66 66 66 66 66 66 - " .
	"66 66 66 66 66 66 66 66  ffffffffffffffff\n");

sub Check {
  my $num = shift;
  my $v1 = shift;
  my $v2 = shift;

  print "" . ($v1 eq $v2 ? "" : "not ") . "ok $num\n";
  print $v1 unless $v1 eq $v2;
}
