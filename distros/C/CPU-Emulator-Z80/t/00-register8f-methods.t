use strict;
$^W = 1;

use Test::More tests => 36;

use CPU::Emulator::Z80::Register8F;

my $f = CPU::Emulator::Z80::Register8F->new();
ok($f->isa('CPU::Emulator::Z80::Register8'),
   "Inheritance tree is hunky-dory");

# S => 0b10000000
# Z => 0b01000000
# 5 => 0b00100000
# H => 0b00010000
# 3 => 0b00001000
# P => 0b00000100
# N => 0b00000010
# C => 0b00000001

$f->set(0b10101010);
ok($f->getS() == 1 &&
   $f->getZ() == 0 &&
   $f->get5() == 1 &&
   $f->getH() == 0 &&
   $f->get3() == 1 &&
   $f->getP() == 0 &&
   $f->getN() == 1 &&
   $f->getC() == 0, "getX works");
   
$f->set(0);
foreach (qw(S Z 5 H 3 P N C)) {
    eval "\$f->set$_();";
    ok(eval "\$f->get$_()", "set$_() works");
    eval "\$f->set$_(0);";
    ok(!eval "\$f->get$_()", "set$_(0) works");
    eval "\$f->set$_(1);";
    ok(eval "\$f->get$_()", "set$_(1) works");
} 
ok($f->get() == 0xFF, "the end result of all those set()s is correct, so nothing lied!");

foreach (qw(S Z 5 H 3 P N C)) {
    eval "\$f->reset$_();";
    ok(!eval "\$f->get$_()", "reset$_() works");
}
ok($f->get() == 0, "the end result of all those reset()s is correct");
