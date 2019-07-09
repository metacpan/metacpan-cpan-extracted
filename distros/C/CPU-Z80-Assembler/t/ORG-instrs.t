#!perl

# $Id$

use warnings;
use strict;
use CPU::Z80::Assembler;
# $CPU::Z80::Assembler::verbose =1;

use Test::More tests => 7;

is	z80asm('
	ORG 0x1234
start
	JP start
'),
	"\xC3\x34\x12", "ORG as first instruction";

is	z80asm('
; hello
	ORG 0x1234
start
	JP start
'),
	"\xC3\x34\x12", "ORG after comment";

is	z80asm('
	NOP
	ORG 1
start
	JP start
'),
	"\x00\xC3\x01\x00", "ORG after some code";

is	z80asm('
	ORG 3
	NOP
	ORG 4
start
	JP start
'),
	"\x00\xC3\x04\x00", "two contiguous ORGs";

$CPU::Z80::Assembler::fill_byte = 0xFF;
is	z80asm('
	ORG 3
	NOP
	ORG 5
start
	JP start
'),
	"\x00\xFF\xC3\x05\x00", "two non-contiguous ORGs";

$CPU::Z80::Assembler::fill_byte = 0x1F;
is	z80asm('
	ORG 2
	NOP
	ORG 5
start
	JP start
'),
	"\x00\x1F\x1F\xC3\x05\x00", "two non-contiguous ORGs";

eval { z80asm('
ORG 0x10
DEFB 0x30, 0x31, 0x32, 0x33, 0x34
ORG 0x11
DEFB 0x35, 0x36, 0x37, 0x38, 0x39
') };
is $@, "-(5) : error: segments overlap, previous ends at 0x0015, next starts at 0x0011\n", "segment overlap";

