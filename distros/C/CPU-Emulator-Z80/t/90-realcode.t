use strict;
$^W = 1;

use Test::More tests => 5;
use CPU::Emulator::Z80;

undef $/;

open(MULTIPLY, 't/multiply.bin') || die("Can't load t/multiply.bin: $!\n");
my $bin = <MULTIPLY>;
$bin .= (' ' x (65536 - length($bin)));
close(MULTIPLY);

my $cpu = CPU::Emulator::Z80->new(memory => $bin);
my $m = $cpu->memory();

$cpu->run();

# 0x0000: LD C, 4                                | 0E 04
# 0x0002: LD E, 200                              | 1E C8
# 0x0004: PUSH HL                                | E5
# 0x0005: PUSH AF                                | F5
# 0x0006: PUSH BC                                | C5
# 0x0007: PUSH DE                                | D5
# 0x0008: LD B, C                                | 41
# 0x0009: LD E, E                                | 5B
# 0x000A: LD HL, 0                               | 21 00 00
# 0x000D: LD D, 0                                | 16 00
# 0x000F: $_macro_4_mulloop                      |
# 0x000F: ADD HL, DE                             | 19
# 0x0010: DJNZ $_macro_4_mulloop                 | 10 FD
# 0x0012: LD ($_macro_4_mulstore), HL            | 22 17 00
# 0x0015: JR $_macro_4_mulexit                   | 18 02
# 0x0017: $_macro_4_mulstore                     |
# 0x0017: DEFW 0                                 | 00 00
# 0x0019: $_macro_4_mulexit                      |
# 0x0019: POP DE                                 | D1
# 0x001A: POP BC                                 | C1
# 0x001B: POP AF                                 | F1
# 0x001C: POP HL                                 | E1
# 0x001D: LD HL, ($_macro_4_mulstore)            | 2A 17 00
# 0x0020: STOP                                   | DD DD 00

ok($cpu->register('AF')->get() == 0, "multiply: AF not altered");
ok($cpu->register('BC')->get() == 4, "multiply: BC not altered");
ok($cpu->register('DE')->get() == 200, "multiply: DE not altered");
ok($cpu->register('HL')->get() == 800, "multiply: result is right");
ok($cpu->memory()->peek16(0x0017) == 800, "multiply: memory frobbed correctly");
