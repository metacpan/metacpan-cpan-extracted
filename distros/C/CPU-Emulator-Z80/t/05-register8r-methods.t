use strict;
$^W = 1;

use Test::More tests => 5;

use CPU::Emulator::Z80::Register8R;

my $r = CPU::Emulator::Z80::Register8R->new(value => 0b01111111);
ok($r->isa('CPU::Emulator::Z80::Register8'),
   "Inheritance tree is hunky-dory");

$r->inc();
ok($r->get() == 0, "wrap around at 7 bits, leaving MSB unset");
$r->inc();
ok($r->get() == 1, "increment normally, leaving MSB unset");
$r->set(255);
$r->inc();
ok($r->get() == 128, "wrap around at 7 bits, leaving MSB unset");
$r->inc();
ok($r->get() == 129, "increment normally, leaving MSB unset");
