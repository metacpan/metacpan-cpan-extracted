#!perl -w

use strict;
use Test::More tests => 10;
use CPU::Emulator::DCPU16::Disassembler;

my $line;

sub get_mem {
    my $hex   = shift;
    my $bytes = join "", pack("H*", $hex);
    my @mem   = CPU::Emulator::DCPU16->bytes_to_array($bytes);
    push @mem, 0x0000 for (0..65536);
    @mem;
}

sub normalise {
    my $asm = shift;
    $asm =~ s!(^\s*|\s*$)!!msg;
    $asm =~ s!\s+! !msg;
    $asm;
}

ok($line = CPU::Emulator::DCPU16::Disassembler->disassemble(0, get_mem("7c010030")), "Disassembled 7c01 0030");
is($line, "SET A, 0x0030", "Got SET");

ok($line = CPU::Emulator::DCPU16::Disassembler->disassemble(0, get_mem("7c100000")), "Disassembled 7c10 0000");
is($line, "JSR 0x0000", "Got JSR");

ok($line = CPU::Emulator::DCPU16::Disassembler->disassemble(0, get_mem("7dc10000")), "Disassembled 7dc1 0000");
is($line, "SET PC, 0x0000", "Got SET PC");

ok($line = CPU::Emulator::DCPU16::Disassembler->disassemble(0, get_mem("21612000")), "Disassembled 2161 2000");
is($line, "SET [0x2000+I], [A]", "Got SET to memory location from indirect register");

my $simple  = ":loop ADD A, 0x1\nIFN A, 0x3\nSET PC, loop";
my $bytes   = CPU::Emulator::DCPU16::Assembler->assemble($simple);
ok(my $asm = CPU::Emulator::DCPU16::Disassembler->dump($bytes), "Dumped the simple object");
is(normalise($asm), ":0x0000 ADD A, 1 IFN A, 3\ SET PC, 0x0000", "Dumped program is correct and has fake labels");