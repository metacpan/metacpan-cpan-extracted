#!perl

# $Id$

use strict;
use warnings;

use Test::More tests => 51;
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
is			$expr->evaluate, 0,		"empty expression is 0";


eval { $expr->bytes };
like $@, qr/^Expr::bytes\(\): unrecognized type '' at/, "type not defined";

$expr->type("ub");
is $expr->bytes, "\0", "unsigned byte";


isa_ok		my $dollar = CPU::Z80::Assembler::Expr->new(type => "ub"),
			'CPU::Z80::Assembler::Expr';
$stream = z80lexer('$');
ok 			$stream = $dollar->parse($stream), "parse expr";
is			$dollar->bytes(0), "\0", "bytes";
is			$dollar->bytes(0xFF), "\xFF", "bytes";
is			$dollar->bytes(-0x80), "\x80", "bytes";

is			$warn, undef, "no warnings";
is			$dollar->bytes(0x100), "\x00", "bytes";
is			$warn, "-(1) : warning: value 0x100 truncated to 0x00\n", "truncated value";
$warn = undef;

is			$warn, undef, "no warnings";
is			$dollar->bytes(0x101), "\x01", "bytes";
is			$warn, "-(1) : warning: value 0x101 truncated to 0x01\n", "truncated value";
$warn = undef;

eval {$dollar->bytes(-0x81)};
is			$@, "-(1) : error: value -0x81 out of range\n", "out of range";



$dollar->type("sb");
is			$dollar->bytes(0), "\0", "bytes";
is			$dollar->bytes(0x7F), "\x7F", "bytes";
is			$dollar->bytes(-0x80), "\x80", "bytes";

eval {$dollar->bytes(-0x81)};
is			$@, "-(1) : error: value -0x81 out of range\n", "out of range";

eval {$dollar->bytes(-0x82)};
is			$@, "-(1) : error: value -0x82 out of range\n", "out of range";

eval {$dollar->bytes(0x80)};
is			$@, "-(1) : error: value 0x80 out of range\n", "out of range";

eval {$dollar->bytes(0x81)};
is			$@, "-(1) : error: value 0x81 out of range\n", "out of range";



$dollar->type("w");
is			$dollar->bytes(0), "\0\0", "bytes";
is			$dollar->bytes(1), "\1\0", "bytes";
is			$dollar->bytes(0x7FFF), "\xFF\x7F", "bytes";
is			$dollar->bytes(0xFFFF), "\xFF\xFF", "bytes";
is			$dollar->bytes(0x10000), "\x00\x00", "bytes no warning";
is			$dollar->bytes(0x10001), "\x01\x00", "bytes no warning";
is			$dollar->bytes(-0x8000), "\x00\x80", "bytes";

eval {$dollar->bytes(-0x8001)};
is			$@, "-(1) : error: value -0x8001 out of range\n", "out of range";

eval {$dollar->bytes(-0x8002)};
is			$@, "-(1) : error: value -0x8002 out of range\n", "out of range";


my %symbols = ( va => 51 );


$stream = z80lexer('10+va+$');
ok 			$stream = $expr->parse($stream), "parse expr";
$expr->type("ub");
is			$expr->bytes(1, \%symbols), chr(10+51+1), "bytes with symbols";
is			$expr->bytes(5, \%symbols), chr(10+51+5), "bytes with symbols";

$symbols{va} = 21;
is			$expr->bytes(1, \%symbols), chr(10+21+1), "bytes with symbols";
is			$expr->bytes(5, \%symbols), chr(10+21+5), "bytes with symbols";

