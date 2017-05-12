#!perl -w

use strict;
use Test::More tests => 10;
use CPU::Emulator::DCPU16::Assembler;

my $bytes;

ok($bytes =  CPU::Emulator::DCPU16::Assembler->assemble("SET A, 0x30"), "Assemble SET");
is(unpack("H*", $bytes), "7c010030", "Got 7c01 0030");

ok($bytes =  CPU::Emulator::DCPU16::Assembler->assemble(":test JSR test"), "Assemble JSR");
is(unpack("H*", $bytes), "7c100000", "Got 7c10 0000");

ok($bytes =  CPU::Emulator::DCPU16::Assembler->assemble(":test SET PC, test"), "Assemble SET PC");
is(unpack("H*", $bytes), "7dc10000", "Got 7dc1 0000");

ok($bytes =  CPU::Emulator::DCPU16::Assembler->assemble("IFN A, 0x10\nSUB A, [0x1000]"), "Assemble IFN and SUB");
is(unpack("H*", $bytes), "c00d78031000", "Got c00d 7803 1000");

ok($bytes =  CPU::Emulator::DCPU16::Assembler->assemble("SET [0x2000+I], [A]"), "Assemble SET to memory location from indirect register");
is(unpack("H*", $bytes), "21612000", "Got 2161 2000");