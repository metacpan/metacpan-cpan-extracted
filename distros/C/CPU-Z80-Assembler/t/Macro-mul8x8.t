#!perl

# $Id$

use warnings;
use strict;
use CPU::Z80::Assembler;
$CPU::Z80::Assembler::verbose = 1 if $ENV{DEBUG};

use Test::More tests => 3;

ok my $bin1 = z80asm('
        MACRO MUL8x8 target, r1, r2 {   ; takes three reg parms, multiplies r1
          PUSH HL                       ; and r2 with result into target
          PUSH AF
          PUSH BC
          PUSH DE
          LD B, r1
          LD E, r2
          LD HL, 0
          LD D, 0
        mulloop
          ADD HL, DE
          DJNZ mulloop
          LD (mulstore), HL
          JR mulexit
        mulstore
          DEFW 0
        mulexit
          POP DE
          POP BC
          POP AF
          POP HL
          LD target, (mulstore)
        }
        MUL8x8 HL, C, E
    '),
    "macro";

ok my $bin2 = z80asm('
          PUSH HL
          PUSH AF
          PUSH BC
          PUSH DE
          LD B, C
          LD E, E
          LD HL, 0
          LD D, 0
        mulloop
          ADD HL, DE
          DJNZ mulloop
          LD (mulstore), HL
          JR mulexit
        mulstore
          DEFW 0
        mulexit
          POP DE
          POP BC
          POP AF
          POP HL
          LD HL, (mulstore)
    '),
    "expanded macro";

is $bin1, $bin2, "macro expansion OK";
