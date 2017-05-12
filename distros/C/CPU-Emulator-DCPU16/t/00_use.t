#!perl -w

use strict;
use Test::More tests => 3;

use_ok( 'CPU::Emulator::DCPU16' );
use_ok( 'CPU::Emulator::DCPU16::Assembler' );
use_ok( 'CPU::Emulator::DCPU16::Disassembler' );