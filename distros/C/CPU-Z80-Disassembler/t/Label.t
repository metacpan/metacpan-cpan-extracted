#!perl

use strict;
use warnings;

use Test::More;

use_ok 'CPU::Z80::Disassembler::Label';

my $label;

eval 	{ CPU::Z80::Disassembler::Label->new() };
like	$@, qr/^invalid name at t.*Label\.t line \d+/;

eval 	{ CPU::Z80::Disassembler::Label->new(0, 23) };
like	$@, qr/^invalid name '23' at t.*Label\.t line \d+/;

eval 	{ CPU::Z80::Disassembler::Label->new(undef, 'B') };
like	$@, qr/^invalid address at t.*Label\.t line \d+/;

eval 	{ CPU::Z80::Disassembler::Label->new('A', 'B') };
like	$@, qr/^invalid address 'A' at t.*Label\.t line \d+/;


isa_ok $label = CPU::Z80::Disassembler::Label->new(23, 'A'),
		'CPU::Z80::Disassembler::Label';

is		$label->name,			'A';
is		$label->comment,		undef;
is		$label->addr,			23;
is		$label->label_string,	"A:\n";
is		$label->equ_string,		"A".(" " x 11)."equ 0x0017\n";
is_deeply [$label->refer_from],	[];

$label->name('B');
$label->comment('this is a label');
is		$label->name,			'B';
is		$label->comment,		'this is a label';
is		$label->addr,			23;
is		$label->label_string,	"B:".(" " x 30).
								"; this is a label\n";
is		$label->equ_string,		"B".(" " x 11)."equ 0x0017".(" " x 10).
								"; this is a label\n";
is		$label->equ_string(8),	"B".(" " x 7)."equ 0x0017".(" " x 14).
								"; this is a label\n";
$label->name('B' x 7);
is		$label->label_string,	"BBBBBBB:".(" " x 24).
								"; this is a label\n";
is		$label->equ_string,		"BBBBBBB".(" " x 5)."equ 0x0017".(" " x 10).
								"; this is a label\n";
is		$label->equ_string(8),	"BBBBBBB equ 0x0017".(" " x 14).
								"; this is a label\n";
								
$label->name('B' x 8);
is		$label->label_string,	"BBBBBBBB:".(" " x 23).
								"; this is a label\n";
is		$label->equ_string,		"BBBBBBBB".(" " x 4)."equ 0x0017".(" " x 10).
								"; this is a label\n";
is		$label->equ_string(8),	"BBBBBBBB equ 0x0017".(" " x 13).
								"; this is a label\n";

$label->comment("line 1\nline 2");
is		$label->label_string,	"BBBBBBBB:".(" " x 23).
								"; line 1\n".(" " x 32)."; line 2\n";
is		$label->equ_string,		"BBBBBBBB".(" " x 4)."equ 0x0017".(" " x 10).
								"; line 1\n".(" " x 32)."; line 2\n";
is		$label->equ_string(8),	"BBBBBBBB equ 0x0017".(" " x 13).
								"; line 1\n".(" " x 32)."; line 2\n";

$label->name('B' x 30);
is		$label->label_string,	('B' x 30).": ".
								"; line 1\n".(" " x 32)."; line 2\n";
is		$label->equ_string,		('B' x 30)." equ 0x0017\n".
								(" " x 32)."; line 1\n".(" " x 32)."; line 2\n";
is		$label->equ_string(8),	('B' x 30)." equ 0x0017\n".
								(" " x 32)."; line 1\n".(" " x 32)."; line 2\n";
								
$label->name('B' x 31);
is		$label->label_string,	('B' x 31).":\n".
								(" " x 32)."; line 1\n".(" " x 32)."; line 2\n";
is		$label->equ_string,		('B' x 31)." equ 0x0017\n".
								(" " x 32)."; line 1\n".(" " x 32)."; line 2\n";
is		$label->equ_string(8),	('B' x 31)." equ 0x0017\n".
								(" " x 32)."; line 1\n".(" " x 32)."; line 2\n";
								
is_deeply [$label->refer_from],	[];


isa_ok $label = CPU::Z80::Disassembler::Label->new(23, 'A', 1, 2, 10, 20),
		'CPU::Z80::Disassembler::Label';

is		$label->name,			'A';
is		$label->addr,			23;
is_deeply [$label->refer_from],	[1, 2, 10, 20];


isa_ok $label = CPU::Z80::Disassembler::Label->new(23, 'A'),
		'CPU::Z80::Disassembler::Label';

is		$label->name,			'A';
is		$label->addr,			23;
is_deeply [$label->refer_from],	[];

$label->add_refer(100);
is_deeply [$label->refer_from],	[100];

$label->add_refer(20);
is_deeply [$label->refer_from],	[20, 100];

$label->add_refer(20);
is_deeply [$label->refer_from],	[20, 100];

$label->add_refer(1);
is_deeply [$label->refer_from],	[1, 20, 100];


done_testing;
