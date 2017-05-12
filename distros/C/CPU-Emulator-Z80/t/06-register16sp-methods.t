use strict;
$^W = 1;

use Test::More tests => 3;

use CPU::Emulator::Z80;
my $c = CPU::Emulator::Z80->new();
ok($c->register('SP')->isa('CPU::Emulator::Z80::Register16SP') &&
   $c->register('SP')->isa('CPU::Emulator::Z80::Register16'),
   "Inheritance tree is hunky-dory");

$c->register('SP')->set(0x43F7);
$c->register('F')->set(0b10011000);
$c->register('SP')->add(2);

ok($c->register('SP')->get() == 0x43F9, "add really does add");
ok($c->register('F')->get() == 0b10011000, "but leaves flags alone");
