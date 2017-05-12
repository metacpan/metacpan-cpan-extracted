use strict;
$^W = 1;

use Test::More tests => 9;

use CPU::Emulator::Z80::Register16;

my $f = CPU::Emulator::Z80::Register16->new();
ok($f->isa('CPU::Emulator::Z80::Register'),
   "Inheritance tree is hunky-dory");

$f->set(0b1010101010101010);
ok($f->get() == 0b1010101010101010, "get() and set() work");

$f->set(-100);
ok($f->get() == ((100 - 1) ^ 0xFFFF), sprintf("-ve is twos-complement shiny: %d == %d == %#016b", $f->get(), $f->getsigned(), $f->get()));
ok($f->getsigned() == -100, "getsigned works");

$f->set(-32768);
ok($f->get() == 32768 && $f->getsigned() == -32768, "can set a maximally -ve value");

$f->set(0b0100000000000000);
ok($f->get() == $f->getsigned(), "for a +ve value, get() and getsigned() are the same");

$f->set(100000); # out of range +ve
ok($f->get() == (100000 & 0xFFFF), "out-of-range set gets truncated at 8 bits using the API");

ok($f->{value} == (100000 & 0xFFFF), "it's even truncated internally when set()ing ...");
$f->{value} = 100000;
ok($f->get() == (100000 & 0xFFFF), "... and when get()ing");
