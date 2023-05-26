#!perl

# $Id$

use warnings;
use strict;
use CPU::Z80::Assembler;
$CPU::Z80::Assembler::verbose = 1 if $ENV{DEBUG};

use Test::More tests => 6;

my($bin1, $bin2);

ok $bin1 = z80asm('
macro m1 {
  ld a,1 : ld b,2
}
  nop
  m1
  nop : m1 : nop : m1 : nop
macro m2 x,y { 
  ld x,y 
}
  m2 a,2 : nop : m2 a,3
');
ok $bin2 = z80asm('
  nop
  ld a,1 : ld b,2
  nop : ld a,1 : ld b,2 : nop : ld a,1 : ld b,2 : nop
  ld a,2 : nop : ld a,3
');
is $bin1, $bin2, "macro expansion OK";


ok $bin1 = z80asm('
macro m1 { nop } : m1 : m1 : m1
');
ok $bin2 = z80asm('
nop : nop : nop
');
is $bin1, $bin2, "macro expansion OK";
