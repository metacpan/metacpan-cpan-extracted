#!perl -w

use strict;
use Test::More tests => 8;
use CPU::Emulator::DCPU16;

my $program   = join "", <DATA>;
ok(my $bytes  = CPU::Emulator::DCPU16::Assembler->assemble($program), "Assemble spec");
ok(my $cpu    = CPU::Emulator::DCPU16->load($bytes), "Loaded bytes");
ok(my $device = $cpu->map_device('TestConsole', 0x8000, 0x817f), "Loaded device");
is($device->{_console}, "", "Console is blank");
is($cpu->register(0), 0x0, "A is 0x0");
ok($cpu->run, "Run all the way through");
is($cpu->memory(0x8000), 0x21, "First char is 0x21");
like($device->{_console}, qr/\!"#\$%&'\(\)\*\+,-\.\/0123456789/, "Console matches");

package TestConsole;

use strict;
use base qw(CPU::Emulator::DCPU16::Device::Console);
# override tick and DESTROY to stop stuff being printed out
sub tick {} 
sub DESTROY {}

package main;

__DATA__
              SET A, 0x0
:loop         SET B, 0x21    ; SET B to be 0x21 (i.e chr !)
              ADD B, A       ; SET B to be 0x21 + incrementer
              SET C, 0x8000  ; 0x8000 is the base of the console device
              ADD C, A       ; SET up the offset into the console device
              SET [C], B     ; SET the memory in the console device
              ADD A, 1       ; Increment A
              IFN B, 0x74    ; Check to see if we've gone past chr ~ 
                 SET PC, loop