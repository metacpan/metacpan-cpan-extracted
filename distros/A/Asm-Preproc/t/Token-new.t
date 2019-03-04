#!perl

# $Id: Token-new.t,v 1.1 2010/09/30 23:00:49 Paulo Exp $

use strict;
use warnings;

use Test::More;
use_ok 'Asm::Preproc::Line';
use_ok 'Asm::Preproc::Token';

my $token;
isa_ok 	$token = Asm::Preproc::Token->new(),
		'Asm::Preproc::Token';
is		$token->type,  			undef, "no type";
is		$token->value, 			undef, "no value";
isa_ok	$token->line,			'Asm::Preproc::Line';
is		$token->line->text, 	undef, "no line text";
is		$token->line->line_nr, 	undef, "no line line_nr";
is		$token->line->file, 	undef, "no line file";

my $line;
isa_ok	$line = Asm::Preproc::Line->new("hello\n", "f.asm", 10),
		'Asm::Preproc::Line';

isa_ok 	$token = Asm::Preproc::Token->new(WORD => "hello", $line),
		'Asm::Preproc::Token';
is		$token->type,  			"WORD", 	"type";
is		$token->value, 			"hello", 	"value";
is		$token->line->text, 	"hello\n", 	"line text";
is		$token->line->line_nr, 	10, 		"line line_nr";
is		$token->line->file, 	"f.asm", 	"line file";

my $token2;
isa_ok	$token2 = $token->clone,
		'Asm::Preproc::Token';
is		$token2->type,  		"WORD", 	"type";
is		$token2->value, 		"hello", 	"value";
is		$token2->line->text, 	"hello\n", 	"line text";
is		$token2->line->line_nr, 10, 		"line line_nr";
is		$token2->line->file, 	"f.asm", 	"line file";

$token->type('');
$token->value('');
$token->line->text('');
$token->line->line_nr('');
$token->line->file('');

is		$token2->type,  		"WORD", 	"type";
is		$token2->value, 		"hello", 	"value";
is		$token2->line->text, 	"hello\n", 	"line text";
is		$token2->line->line_nr, 10, 		"line line_nr";
is		$token2->line->file, 	"f.asm", 	"line file";

is		$token->type,  			'', "no type";
is		$token->value, 			'', "no value";
is		$token->line->text, 	'', 	"no line text";
is		$token->line->line_nr, 	'', "no line line_nr";
is		$token->line->file, 	'', 	"no line file";

done_testing();