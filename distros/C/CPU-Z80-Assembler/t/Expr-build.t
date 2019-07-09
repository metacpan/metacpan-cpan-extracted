#!perl

# $Id$

use strict;
use warnings;

use Test::More tests => 39;
use_ok 'CPU::Z80::Assembler';
use_ok 'CPU::Z80::Assembler::Expr';
use_ok 'Asm::Preproc::Line';
use_ok 'Iterator::Simple::Lookahead';
require_ok 't/test_utils.pl';

our $stream;

my $warn; 
$SIG{__WARN__} = sub {$warn = shift};
END { is $warn, undef, "no warnings"; }

# construct
isa_ok		my $line = Asm::Preproc::Line->new("hello\n", "f.asm", 10),
			'Asm::Preproc::Line';

isa_ok		my $expr = CPU::Z80::Assembler::Expr->new(line => $line),
			'CPU::Z80::Assembler::Expr';
is_deeply	$expr->child,	[], 	"no children";
is			$expr->line->text, 		"hello\n", 	"line text";
is			$expr->line->line_nr, 	10, 		"line line_nr";
is			$expr->line->file, 		"f.asm", 	"line file";
is			$expr->evaluate, 0,			"empty expression is 0";


$stream = z80lexer(
'#line 3 "FILE"
6+7
');
ok 			$stream = $expr->parse($stream), "parse expr";
is			$expr->line->text, 		"6+7\n", 	"line text";
is			$expr->line->line_nr, 	3,	 		"line line_nr";
is			$expr->line->file, 		"FILE", 	"line file";
is			$expr->evaluate, 6+7,		"eval expression";

my $new_expr;
isa_ok 		$new_expr = $expr->build("{}"), 'CPU::Z80::Assembler::Expr';
is			$new_expr->evaluate, 6+7,		"eval expression";
is			$new_expr->line->text, 		"6+7\n", 	"line text";
is			$new_expr->line->line_nr, 	3,	 		"line line_nr";
is			$new_expr->line->file, 		"FILE", 	"line file";

isa_ok 		$new_expr = $expr->build("2*{}"), 'CPU::Z80::Assembler::Expr';
is			$new_expr->evaluate, 2*(6+7),	"eval expression";
is			$new_expr->line->text, 		"6+7\n", 	"line text";
is			$new_expr->line->line_nr, 	3,	 		"line line_nr";
is			$new_expr->line->file, 		"FILE", 	"line file";

eval {$expr->build("{")};
like $@, qr/^unmatched \{\} at.*/, "unbalanced braces";

eval {$expr->build("{2")};
like $@, qr/^unmatched \{\} at.*/, "unbalanced braces";

isa_ok 		$new_expr = $expr->build("{}"), 'CPU::Z80::Assembler::Expr';
is			$new_expr->evaluate, 6+7,		"eval expression";
is 			$new_expr->type, undef, 		"type not defined";

isa_ok 		$new_expr = $expr->build("{}", type => "w"), 'CPU::Z80::Assembler::Expr';
is			$new_expr->evaluate, 6+7,		"eval expression";
is 			$new_expr->type, "w",	 		"type not defined";

