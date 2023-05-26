#!perl

# $Id$

use strict;
use warnings;

use Test::More tests => 17533;

use_ok 'CPU::Z80::Assembler';
use_ok 'CPU::Z80::Assembler::Program';
use_ok 'CPU::Z80::Assembler::JumpOpcode';
use_ok 'CPU::Z80::Assembler::Opcode';
use_ok 'CPU::Z80::Assembler::Expr';
use_ok 'Asm::Preproc::Line';
use_ok 'Asm::Preproc::Token';

my($program, $bytes, $code, %labels);

sub NEW () {
	my $caller_line = (caller)[2];
	ok $caller_line, "[line $caller_line]";
	isa_ok	$program = CPU::Z80::Assembler::Program->new(),
			'CPU::Z80::Assembler::Program';
	$bytes = "";
	$code = "";
	%labels = ();
}

sub LABEL ($) {
	my($label) = @_;
	my $caller_line = (caller)[2];
	ok $caller_line, "[line $caller_line]";
	
	my $text = "$label:\n";
	isa_ok my $line = Asm::Preproc::Line->new($text, "f.asm", 1),
			'Asm::Preproc::Line';

	$program->add_label($label, $line);
	$bytes .= "";
	$code .= $text;
	$labels{$label} = length($bytes);
}

sub NOPs ($) {
	my($num) = @_;
	my $caller_line = (caller)[2];
	ok $caller_line, "[line $caller_line]";
	
	my $text = " NOP :" x $num . "\n";
	isa_ok my $line = Asm::Preproc::Line->new($text, "f.asm", 1),
			'Asm::Preproc::Line';

	isa_ok my $nops = CPU::Z80::Assembler::Opcode->new(
									child 	=> [(0) x $num],
									line	=> $line),
			'CPU::Z80::Assembler::Opcode';
			
	$program->add_opcodes($nops);
	$bytes .= "\0" x $num;
	$code .= $text;
}

sub JUMP ($$$$) {
	my($instr, $short_opcodes, $long_opcodes, $instr_bytes) = @_;
	my $caller_line = (caller)[2];
	ok $caller_line, "[line $caller_line]";
	
	my $label = (split(' ', $instr))[-1];
	my $text = " ".$instr."\n";
	
	isa_ok my $line = Asm::Preproc::Line->new($text, "f.asm", 1),
			'Asm::Preproc::Line';
			
	isa_ok my $t_name = Asm::Preproc::Token->new(NAME => $label, $line),
			'Asm::Preproc::Token';
	isa_ok my $t_minus = Asm::Preproc::Token->new('-' => '-', $line),
			'Asm::Preproc::Token';
	isa_ok my $t_dollar = Asm::Preproc::Token->new(NAME => '$', $line),
			'Asm::Preproc::Token';
	isa_ok my $t_2 = Asm::Preproc::Token->new(NUMBER => 2, $line),
			'Asm::Preproc::Token';
			
	isa_ok my $short_expr = CPU::Z80::Assembler::Expr->new(
									child	=> [$t_name, $t_minus, $t_dollar, $t_minus, $t_2],
									type	=> 'sb',
									line	=> $line),
			'CPU::Z80::Assembler::Expr';
	isa_ok my $long_expr = CPU::Z80::Assembler::Expr->new(
									child	=> [$t_name],
									type	=> 'w',
									line	=> $line),
			'CPU::Z80::Assembler::Expr';

	isa_ok my $short_jump = CPU::Z80::Assembler::Opcode->new(
									child 	=> [@$short_opcodes, $short_expr],
									line	=> $line),
			'CPU::Z80::Assembler::Opcode';
	isa_ok my $long_jump = CPU::Z80::Assembler::Opcode->new(
									child 	=> [@$long_opcodes, $long_expr, undef],
									line	=> $line),
			'CPU::Z80::Assembler::Opcode';
	
	isa_ok my $jump = CPU::Z80::Assembler::JumpOpcode->new(
									short_jump 	=> $short_jump,
									long_jump	=> $long_jump),
			'CPU::Z80::Assembler::JumpOpcode';

	$program->add_opcodes($jump);
	for (@$instr_bytes) {
		$bytes .= chr($_ & 0xFF);
	}
	$code .= $text;
}

sub TEST () {
	my $caller_line = (caller)[2];
	is $program->bytes, $bytes, 	"[line $caller_line] assembled OK";
	is $program->bytes, $bytes, 	"[line $caller_line] second run also OK";
	is z80asm($code), 	$bytes, 	"[line $caller_line] z80asm OK";
	while (my($label, $value) = each %labels) {
		is $program->symbols->{$label}->evaluate, $value, 
									"[line $caller_line] label $label = $value";
	}
}


for my $test (
				["DJNZ", 	[0x10], [0x05, 0xC2]],
				["JR",		[0x18], [0xC3]],
				["JR NZ,",	[0x20], [0xC2]],
				["JR Z,",	[0x28], [0xCA]],
				["JR NC,",	[0x30], [0xD2]],
				["JR C,",	[0x38], [0xDA]],
			) {
	my($opcode, $short, $long) = @$test;
	ok 1, "[$opcode, [@$short], [@$long]]";

	# One isolated jump +127
	NEW;
	JUMP	"$opcode L1", [@$short], [@$long], [@$short, 0x7F];
	NOPs	127;
	LABEL	"L1";
	TEST;


	# One isolated jump +128
	NEW;
	JUMP	"$opcode L1", [@$short], [@$long], [@$long, 128+scalar(@$long)+2, 0x00];
	NOPs	128;
	LABEL	"L1";
	TEST;


	# One isolated jump -128
	NEW;
	LABEL	"L1";
	NOPs	126;
	JUMP	"$opcode L1", [@$short], [@$long], [@$short, 0x80];
	TEST;


	# One isolated jump -129
	NEW;
	LABEL	"L1";
	NOPs	127;
	JUMP	"$opcode L1", [@$short], [@$long], [@$long, 0x00, 0x00];
	TEST;


	# Cascade of changes with backwards jump
	NEW;
	LABEL	"L1";
	for (0..63) {
		JUMP	"$opcode L1", [@$short], [@$long], [@$short, 0 - 2*$_ - 2];
	}
	for (64..127) {
		JUMP	"$opcode L1", [@$short], [@$long], [@$long, 0x00, 0x00];
	}
	TEST;


	# Cascade of changes with forward jump
	NEW;
	my $l1 = 64 * (scalar(@$short)+1) + 64 * (scalar(@$long)+2);
	for (0..63) {
		JUMP	"$opcode L1", [@$short], [@$long], [@$long, ($l1 & 0xFF), ($l1 >> 8)];
	}
	for (64..127) {
		JUMP	"$opcode L1", [@$short], [@$long], [@$short, 2 * (127-$_)];
	}
	LABEL	"L1";
	TEST;
}


#open(F, ">bytes1.bin") or die; binmode(F); print F $program->bytes;
#open(F, ">bytes2.bin") or die; binmode(F); print F $bytes;
