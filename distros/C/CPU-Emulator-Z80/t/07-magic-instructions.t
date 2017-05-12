use strict;
$^W = 1;

use Test::More tests => 7;

use CPU::Emulator::Z80;

my $cpu = CPU::Emulator::Z80->new();

foreach (0xDDDD, 0xDDFD, 0xFDDD, 0xFDFD) {
    $cpu->register('PC')->set(0);
    $cpu->memory()->poke16(0, 0);  # NOP; NOP
    $cpu->memory()->poke16(2, $_);
    $cpu->memory()->poke(4, 0);    # STOP
    $cpu->memory()->poke16(5, 0);    # NOP; NOP
    $cpu->memory()->poke16(7, 0);    # NOP; NOP
    $cpu->run(7);
    ok($cpu->register('PC')->get() == 5, sprintf("0x%04X00 STOP instruction works (as does the dispatch table)", $_));
}
ok($cpu->stopped(), "stopped() method agrees");
$cpu->register('PC')->set(0);
$cpu->run(2);
ok(!$cpu->stopped(), "stopped() method is false when we didn't STOP");

$cpu->memory()->poke16(2, 0xDDDD);
$cpu->memory()->poke(4, 0xFF); # undefined instr
$cpu->register('PC')->set(0);
eval { $cpu->run(7); };
ok($@, "0xDDDDFF really is fatal");
