use strict;
use warnings;

use_ok 'Iterator::Simple::Lookahead';
use_ok 'Asm::Preproc::Line';
use_ok 'CPU::Z80::Assembler::Opcode';

sub opcodes {
	my($start, $line_nr) = @_;
	my @opcodes;

	my $caller_line = (caller)[2];

	ok $caller_line, "[line $caller_line] opcodes";
	
	for (0..2) {
		isa_ok my $line = Asm::Preproc::Line->new("line ".($line_nr+$_)."\n",
												  "f.asm", $line_nr+$_),
				'Asm::Preproc::Line';
		isa_ok my $opcode = CPU::Z80::Assembler::Opcode->new(
						child => [ord($start)+$_],	
						line => $line 
				), 'CPU::Z80::Assembler::Opcode';
		push @opcodes, $opcode;
	}
	@opcodes;
}


sub test_line { my($text, $line_nr, $file) = @_;
	our $stream;

	my $caller_line = (caller)[2];
	my $token = $stream->next;
	isa_ok $token, 'Asm::Preproc::Line';
	is $text, 		$token->text, 		"[line $caller_line] text";
	is $line_nr, 	$token->line_nr, 	"[line $caller_line] line_nr";
	is $file, 		$token->file, 		"[line $caller_line] file";
}

sub test_token_line { my($text, $line_nr, $file) = @_;
	our $stream;
	our $line;
	
	my $caller_line = (caller)[2];
	ok my $token = $stream->peek, "[line $caller_line] peek";
	isa_ok $line = $token->line, 'Asm::Preproc::Line';
	
	is $line->text, 	$text, 		"[line $caller_line] text";
	is $line->line_nr, 	$line_nr, 	"[line $caller_line] line_nr";
	is $line->file, 	$file, 		"[line $caller_line] file";
}

sub test_token { my($type, $value) = @_;
	our $stream;
	our $line;
	
	my $caller_line = (caller)[2];
	ok my $token = $stream->next, "[line $caller_line] drop";
	
	is $token->type, 			$type,				"[line $caller_line] type";
	is $token->value, 			$value,				"[line $caller_line] value";
	is $token->line->text, 		$line->text, 		"[line $caller_line] text";
	is $token->line->line_nr, 	$line->line_nr, 	"[line $caller_line] line_nr";
	is $token->line->file, 		$line->file, 		"[line $caller_line] file";
}


sub test_eof {
	our $stream;
	
	my $caller_line = (caller)[2];
	is $stream->next, undef, "[line $caller_line] eof 1";	
	is $stream->next, undef, "[line $caller_line] eof 2";	
}

1;
