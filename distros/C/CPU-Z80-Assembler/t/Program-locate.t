#!perl

# $Id$

use strict;
use warnings;

use Test::More tests => 44;

use_ok 'CPU::Z80::Assembler';
use_ok 'CPU::Z80::Assembler::Program';
use_ok 'CPU::Z80::Assembler::Segment';
use_ok 'CPU::Z80::Assembler::Expr';
use_ok 'CPU::Z80::Assembler::Opcode';
use_ok 'Asm::Preproc::Line';

require_ok 't/test_utils.pl';

our $stream;

isa_ok		my $program = CPU::Z80::Assembler::Program->new(),
			'CPU::Z80::Assembler::Program';

$program->symbols->{va} = 51;

isa_ok		my $expr = CPU::Z80::Assembler::Expr->new(type => "w"),
			'CPU::Z80::Assembler::Expr';

$stream = z80lexer('$+va');
ok 			$stream = $expr->parse($stream), "parse expr";
is			$expr->evaluate(10, $program->symbols), 10+51, "eval expr";


isa_ok		my $line1 = Asm::Preproc::Line->new("line 1\n", "f.asm", 1),
			'Asm::Preproc::Line';
isa_ok		my $line2 = Asm::Preproc::Line->new("line 2\n", "f.asm", 2),
			'Asm::Preproc::Line';
isa_ok		my $line3 = Asm::Preproc::Line->new("line 3\n", "f.asm", 3),
			'Asm::Preproc::Line';

isa_ok 		my $segment = $program->segment("CODE"),
			'CPU::Z80::Assembler::Segment';

my @opcodes = (
		CPU::Z80::Assembler::Opcode->new(child => [1,2,3], 			line => $line1 ),
		CPU::Z80::Assembler::Opcode->new(child => [4,$expr,undef],	line => $line2 ),
		CPU::Z80::Assembler::Opcode->new(child => [5,6,7],			line => $line3 ),
);

$program->add_opcodes(@opcodes);
is $program->segment->address, undef, "address not defined";

is 			$program->_locate,		9,				"_locate";
is			$segment->name,			"CODE",			"name";
is			$segment->address, 		0, 				"allocated address";
is			$segment->line->text, 	$line1->text, 	"line text";
is			$segment->line->line_nr,$line1->line_nr,"line line_nr";
is			$segment->line->file, 	$line1->file, 	"line file";
is			$segment->child->[0]->address, 0, 		"allocated address";
is			$segment->child->[1]->address, 3, 		"allocated address";
is			$segment->child->[2]->address, 6, 		"allocated address";

$program->symbols->{va} = 51;
is 			$program->bytes(), "\x01\x02\x03\x04".chr(3+51).chr(0)."\x05\x06\x07",
			"bytes";

$program->symbols->{va} = 11;
is 			$program->bytes(), "\x01\x02\x03\x04".chr(3+11).chr(0)."\x05\x06\x07",
			"bytes";

$segment->address(10);
is 			$program->_locate,		19,				"_locate";
is			$segment->address, 		10, 			"allocated address";
is			$segment->child->[0]->address, 10, 		"allocated address";
is			$segment->child->[1]->address, 13, 		"allocated address";
is			$segment->child->[2]->address, 16, 		"allocated address";


$program->symbols->{va} = 51;
is 			$program->bytes(), "\x01\x02\x03\x04".chr(13+51).chr(0)."\x05\x06\x07",
			"bytes";

$program->symbols->{va} = 11;
is 			$program->bytes(), "\x01\x02\x03\x04".chr(13+11).chr(0)."\x05\x06\x07",
			"bytes";

		
$segment->address(1);
is 			$program->_locate,		10,				"_locate";
is			$segment->address, 		1,	 			"allocated address";
is			$segment->child->[0]->address, 1, 		"allocated address";
is			$segment->child->[1]->address, 4, 		"allocated address";
is			$segment->child->[2]->address, 7, 		"allocated address";


$program->symbols->{va} = 51;
is 			$program->bytes(), "\x01\x02\x03\x04".chr(4+51).chr(0)."\x05\x06\x07",
			"bytes";

$program->symbols->{va} = 11;
is 			$program->bytes(), "\x01\x02\x03\x04".chr(4+11).chr(0)."\x05\x06\x07",
			"bytes";
