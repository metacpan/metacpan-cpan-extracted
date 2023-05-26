#!perl

# $Id$

use strict;
use warnings;

use Test::More tests => 29;

use_ok 'CPU::Z80::Assembler::Program';
use_ok 'Asm::Preproc::Line';
require_ok 't/test_utils.pl';

isa_ok		my $program = CPU::Z80::Assembler::Program->new(),
			'CPU::Z80::Assembler::Program';

isa_ok my $line1 = Asm::Preproc::Line->new("s1:\n", "f.asm", 1),
			'Asm::Preproc::Line';
$program->add_label("s1", $line1);

isa_ok 	$program->symbols->{s1}, 				'CPU::Z80::Assembler::Opcode';
is		$program->symbols->{s1}->line->text, 	"s1:\n",	"text";
is		$program->symbols->{s1}->line->line_nr, 1,			"line_nr";
is		$program->symbols->{s1}->line->file, 	"f.asm",	"file";

$program->add_opcodes(opcodes('A', 2));

isa_ok my $line5a = Asm::Preproc::Line->new("s1:\n", "f.asm", 5),
			'Asm::Preproc::Line';
eval {$program->add_label("s1", $line5a)};
is $@, "f.asm(5) : error: duplicate label definition\n", "duplicate label";

isa_ok my $line5b = Asm::Preproc::Line->new("s5:\n", "f.asm", 5),
			'Asm::Preproc::Line';
$program->add_label("s5", $line5b);

isa_ok 	$program->symbols->{s5}, 				'CPU::Z80::Assembler::Opcode';
is		$program->symbols->{s5}->line->text, 	"s5:\n",	"text";
is		$program->symbols->{s5}->line->line_nr, 5,			"line_nr";
is		$program->symbols->{s5}->line->file, 	"f.asm",	"file";


is		$program->bytes, "ABC", "bytes";
is		$program->symbols->{s1}->evaluate, 0,	"label value";
is		$program->symbols->{s5}->evaluate, 3,	"label value";
