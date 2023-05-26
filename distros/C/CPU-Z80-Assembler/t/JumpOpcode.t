#!perl

# $Id$

use strict;
use warnings;

use Test::More;

use_ok 'CPU::Z80::Assembler::JumpOpcode';
use_ok 'CPU::Z80::Assembler::Opcode';
use_ok 'Asm::Preproc::Line';
use_ok 'CPU::Z80::Assembler';
use_ok 'CPU::Z80::Assembler::Expr';

isa_ok		my $expr = CPU::Z80::Assembler::Expr->new(type => "sb"),
			'CPU::Z80::Assembler::Expr';
my $stream = z80lexer('2');
ok 			$expr->parse($stream), "parse expr";
is			$expr->evaluate, 2, "eval expr";

isa_ok		my $line1 = Asm::Preproc::Line->new(1, "f.asm", 1),
			'Asm::Preproc::Line';

isa_ok		my $line2 = Asm::Preproc::Line->new(2, "f.asm", 2),
			'Asm::Preproc::Line';

isa_ok		my $line3 = Asm::Preproc::Line->new(3, "f.asm", 3),
			'Asm::Preproc::Line';

isa_ok		my $short_jump = CPU::Z80::Assembler::Opcode->new(
						address => 1, line => $line1, child => [1,$expr]),
			'CPU::Z80::Assembler::Opcode';

isa_ok		my $long_jump = CPU::Z80::Assembler::Opcode->new(
						address => 2, line => $line2, child => [1,2,3]),
			'CPU::Z80::Assembler::Opcode';

isa_ok		my $jump = CPU::Z80::Assembler::JumpOpcode->new(),
			'CPU::Z80::Assembler::JumpOpcode';

is_deeply	$jump->short_jump->child,[], 	"no children";
is_deeply	$jump->long_jump->child,	[], 	"no children";
is			$jump->address,	 		undef, 	"address";
is			$jump->line->text, 		undef, 	"line text";
is			$jump->line->line_nr, 	undef, 	"line line_nr";
is			$jump->line->file, 		undef, 	"line file";

isa_ok		$jump = CPU::Z80::Assembler::JumpOpcode->new(
						short_jump 	=> $short_jump,
						long_jump	=> $long_jump ),
			'CPU::Z80::Assembler::JumpOpcode';

is_deeply	$jump->short_jump->child,[1,$expr],	"short children";
is_deeply	$jump->long_jump->child,	[1,2,3],"long children";
is			$jump->address,	 		1, 		"short address";
is			$jump->line->text, 		1, 		"line text";
is			$jump->line->line_nr, 	1, 		"line line_nr";
is			$jump->line->file, 		"f.asm","line file";
is 			$jump->size,			2,		"short size";
is			$jump->bytes,			"\1\2",	"short bytes";
is 			$jump->short_jump_dist,	2,		"short jump distance";

# modify address and line
$jump->address(3);
$jump->line($line3);

is			$jump->address,	 			3, 		"short address";
is			$jump->short_jump->address,	3, 		"short address";
is			$jump->long_jump->address,	3, 		"short address";
is			$jump->line->text, 			3, 		"line text";
is			$jump->line->line_nr, 		3, 		"line line_nr";

done_testing();
