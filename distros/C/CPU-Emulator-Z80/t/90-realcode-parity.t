use strict;
use warnings;

use Test::More tests => 256;
use CPU::Emulator::Z80;

undef $/;

open(PARITY, 't/parity.bin') || die("Can't load t/parity.bin: $!\n");
my $bin = <PARITY>;
$bin .= (' ' x (65536 - length($bin)));
close(PARITY);

my $cpu = CPU::Emulator::Z80->new(memory => $bin);
my $m = $cpu->memory();

$cpu->run();

for(my $i = 0; $i < 256; $i++) {
  ok($cpu->memory()->peek8($i) == parity($i), "$i has parity ".parity($i));
}

sub parity { # return 1 for even parity, 0 for odd
  (my $bits_set = sprintf("%08b", shift)) =~ s/0//g;
  return length($bits_set) % 2;
}
