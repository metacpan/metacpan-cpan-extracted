use strict;
$^W = 1;

use Test::More tests => 6;

use CPU::Emulator::Z80;

my $cpu = CPU::Emulator::Z80->new();
my $m = $cpu->memory();

$cpu->run(1); # set PC to 1
$cpu->nmi();
ok($cpu->{NMI}, "NMI raises internal flag even if ints are disabled");
$cpu->run(1);
ok($cpu->register('PC')->get() == 0x0066, "NMIs vector OK");
ok($cpu->register('SP')->get() == 0xFFFE, "SP get diddled right");
ok($m->peek16($cpu->register('SP')->get()) == 1, "PC pushed correctly");

$cpu->_EI();
ok($cpu->{iff1} == 1, "EI turns on IFF1");
$cpu->nmi();
ok($cpu->{iff1} == 0 && $cpu->{iff2} == 1, "NMI disables interrupts and saves IFF1 into IFF2");
