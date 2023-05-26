#!perl

# $Id$

use strict;
use warnings;

use Test::More tests => 57;
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


isa_ok		my $dollar = CPU::Z80::Assembler::Expr->new,
			'CPU::Z80::Assembler::Expr';
$stream = z80lexer('$');
ok 			$stream = $dollar->parse($stream), "parse expr";
is			$dollar->evaluate(0), 0, "eval";
is			$dollar->evaluate(1), 1, "eval";
is			$dollar->evaluate(11), 11, "eval";

$stream = z80lexer('10+$');
ok 			$stream = $expr->parse($stream), "parse expr";
is			$expr->evaluate(0), 10, "eval";
is			$expr->evaluate(1), 11, "eval";
is			$expr->evaluate(11), 21, "eval";

my %symbols = ( va => 51, vb => $dollar, vc => $expr );

$stream = z80lexer('10+va');
ok 			$stream = $expr->parse($stream), "parse expr";
is			$expr->evaluate(0, \%symbols), 61, "eval";
is			$expr->evaluate(1, \%symbols), 61, "eval";

$stream = z80lexer('10+vb');
ok 			$stream = $expr->parse($stream), "parse expr";
is			$expr->evaluate(0, \%symbols), 10, "eval";
is			$expr->evaluate(1, \%symbols), 11, "eval";

$stream = z80lexer('""');
ok 			$stream = $expr->parse($stream), "parse expr";
is			$expr->evaluate, 0, "eval";

$stream = z80lexer("''");
ok 			$stream = $expr->parse($stream), "parse expr";
is			$expr->evaluate, 0, "eval";

$stream = z80lexer('"A"');
ok 			$stream = $expr->parse($stream), "parse expr";
is			$expr->evaluate, ord('A'), "eval";

$stream = z80lexer('"AZ"');
ok 			$stream = $expr->parse($stream), "parse expr";
is			$expr->evaluate, ord('A') + (ord('Z') << 8), "eval";

$stream = z80lexer('"AZY"');
ok 			$stream = $expr->parse($stream), "parse expr";
is			$warn, undef, "no warnings";
is			$expr->evaluate, ord('A') + (ord('Z') << 8), "eval";
is			$warn, "-(1) : warning: Expression AZY: extra bytes ignored\n", "warning";
$warn = undef;

$stream = z80lexer('10+vc');
ok 			$stream = $expr->parse($stream), "parse expr";
eval {$expr->evaluate(0, \%symbols)};
is			$@, "-(1) : error: Circular reference computing 'vc'\n",
			"circular reference";

# simulate bug:
#	err equ 10
#	y0  equ err
#	ld a,(iy+err-y0) ; gives circular reference error, and should not
isa_ok		my $err_expr = CPU::Z80::Assembler::Expr->new(line => $line),
			'CPU::Z80::Assembler::Expr';
$stream = z80lexer('10');
ok 			$stream = $err_expr->parse($stream), "parse expr";
$symbols{err} = $err_expr;

isa_ok		my $y0_expr = CPU::Z80::Assembler::Expr->new(line => $line),
			'CPU::Z80::Assembler::Expr';
$stream = z80lexer('err');
ok 			$stream = $y0_expr->parse($stream), "parse expr";
$symbols{y0} = $y0_expr;

$stream = z80lexer('err-y0');
ok 			$stream = $expr->parse($stream), "parse expr";
is			$expr->evaluate(0, \%symbols), 0, "eval";

$stream = z80lexer('10+vd');
ok 			$stream = $expr->parse($stream), "parse expr";
eval {$expr->evaluate(0, \%symbols)};
is			$@, "-(1) : error: Symbol 'vd' not defined\n",
			"undefined";

$stream = z80lexer('10/(51-va)');
ok 			$stream = $expr->parse($stream), "parse expr";
eval {$expr->evaluate(0, \%symbols)};
is			$@, "-(1) : error: Expression '10 / ( 51 - 51 )': Illegal division by zero\n",
			"division by zero";

$stream = z80lexer('10+');
eval { $expr->parse($stream) };
is			$@, "-(1) : error: expected one of (\"(\" NAME NUMBER STRING) at \"\\n\"\n",
			"syntax error";

$stream = z80lexer('10+hl');
eval { $expr->parse($stream) };
is			$@, "-(1) : error: expected one of (\"(\" NAME NUMBER STRING) at hl\n",
			"syntax error";

