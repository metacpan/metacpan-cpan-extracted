#!perl -w

use strict;
use Test::More tests => 15;
use CPU::Emulator::DCPU16;

my $bytes;
my $cpu    = CPU::Emulator::DCPU16->new;
my $simple = ":loop ADD A, 0x1\nIFN A, 0x3\nSET PC, loop";
ok($bytes  = CPU::Emulator::DCPU16::Assembler->assemble($simple), "Assemble simple");
ok($cpu->load($bytes)->run, "Run simple program");
is($cpu->register(0), 0x3, "A is 0x3");
is($cpu->pc, 0x4, "PC is 0x4");

my $spec   = join "", <DATA>;
ok($bytes  = CPU::Emulator::DCPU16::Assembler->assemble($spec), "Assemble spec");

ok($cpu->load($bytes)->run(limit => 1), "Run spec with a limit of 1");
is($cpu->register(0), 0x30, "A is 0x30");
is($cpu->pc, 0x2, "PC is 0x2");

ok($cpu->load($bytes)->run(limit => 3), "Run spec with a limit of 1");
is($cpu->register(0), 0x10, "A is 0x10");
is($cpu->pc, 0x7, "PC is 0x7");

ok($cpu->load($bytes)->run(limit => 51), "Run spec with a limit of 51");
is($cpu->register(0), 0x2000, "A is 0x2000");
is($cpu->register(3), 0x40, "X is 0x40");
is($cpu->pc, 0x001a, "PC is 0x001a");


__DATA__
; Try some basic stuff
              SET A, 0x30              ; 7c01 0030
              SET [0x1000], 0x20       ; 7de1 1000 0020
              SUB A, [0x1000]          ; 7803 1000
              IFN A, 0x10              ; c00d 
                 SET PC, crash         ; 7dc1 001a [*]

; Do a loopy thing
              SET I, 10                ; a861
              SET A, 0x2000            ; 7c01 2000
:loop         SET [0x2000+I], [A]      ; 2161 2000
              SUB I, 1                 ; 8463
              IFN I, 0                 ; 806d
                 SET PC, loop          ; 7dc1 000d [*]

; Call a subroutine
              SET X, 0x4               ; 9031
              JSR testsub              ; 7c10 0018 [*]
              SET PC, crash            ; 7dc1 001a [*]

:testsub      SHL X, 4                 ; 9037
              SET PC, POP              ; 61c1

; Hang forever. X should now be 0x40 if everything went right.
:crash        SET PC, crash            ; 7dc1 001a [*]