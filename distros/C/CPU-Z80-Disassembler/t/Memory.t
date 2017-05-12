#!perl

use strict;
use warnings;

use Test::More;

use_ok 'CPU::Z80::Disassembler::Memory';

my $mem;
my $it;

#------------------------------------------------------------------------------
# poke_str
isa_ok 	$mem = CPU::Z80::Disassembler::Memory->new,
		'CPU::Z80::Disassembler::Memory';

$mem->poke_str(0, '');
isa_ok	$it = $mem->loaded_iter, 'CODE';
is_deeply [$it->()], [];
		

isa_ok 	$mem = CPU::Z80::Disassembler::Memory->new,
		'CPU::Z80::Disassembler::Memory';

eval	{ $mem->poke_str(0x10000, 'AB') };
like	$@, qr/^address 0x10000 out of range at t.*?Memory.t line \d+/;

eval	{ $mem->poke_str(0xFFFF, 'AB') };
like	$@, qr/^address 0x10000 out of range at t.*?Memory.t line \d+/;

eval	{ $mem->poke_str(-2, 'CD') };
like	$@, qr/^address -0x02 out of range at t.*?Memory.t line \d+/;

eval	{ $mem->poke_str(-1, 'CD') };
like	$@, qr/^address -0x01 out of range at t.*?Memory.t line \d+/;

$mem->poke_str(0, 'CD');
is		$mem->peek(0), ord('C');
is		$mem->peek(1), ord('D');

$mem->poke_str(0xFFFE, 'AB');
is		$mem->peek(0xFFFE), ord('A');
is		$mem->peek(0xFFFF), ord('B');

isa_ok	$it = $mem->loaded_iter, 'CODE';
is_deeply [$it->()], [0, 1];
is_deeply [$it->()], [65534, 65535];
is_deeply [$it->()], [];

#------------------------------------------------------------------------------
# load_file, file not found
isa_ok $mem = CPU::Z80::Disassembler::Memory->new, 
		'CPU::Z80::Disassembler::Memory';

eval 	{ $mem->load_file('zx48.rom') };
like 	$@, qr/read_file 'zx48.rom' - sysopen/i;

#------------------------------------------------------------------------------
# load_file, all default
isa_ok $mem = CPU::Z80::Disassembler::Memory->new, 
		'CPU::Z80::Disassembler::Memory';

$mem->load_file('t/data/zx48.rom');
is		$mem->peek(0),		0xF3;
is		$mem->peek(1),		0xAF;
is		$mem->peek(0x3FFE),	0x42;
is		$mem->peek(0x3FFF),	0x3C;
is		$mem->peek(0x4000),	undef;
is		$mem->peek(0xFFFF),	undef;

isa_ok	$it = $mem->loaded_iter, 'CODE';
is_deeply [$it->()], [0, 0x3FFF];
is_deeply [$it->()], [];

#------------------------------------------------------------------------------
# load_file, at address
isa_ok $mem = CPU::Z80::Disassembler::Memory->new, 
		'CPU::Z80::Disassembler::Memory';

$mem->load_file('t/data/zx48.rom', 0xC000);
is		$mem->peek(0xBFFF),	undef;
is		$mem->peek(0xC000),	0xF3;
is		$mem->peek(0xC001),	0xAF;
is		$mem->peek(0xFFFE),	0x42;
is		$mem->peek(0xFFFF),	0x3C;

isa_ok	$it = $mem->loaded_iter, 'CODE';
is_deeply [$it->()], [0xC000, 0xFFFF];
is_deeply [$it->()], [];

eval 	{ $mem->load_file('t/data/zx48.rom', 0xC001) };
like 	$@, qr/^address 0x10000 out of range at t.*?Memory.t line \d+/;

#------------------------------------------------------------------------------
# load_file, at address, skip header
isa_ok $mem = CPU::Z80::Disassembler::Memory->new, 
		'CPU::Z80::Disassembler::Memory';

$mem->load_file('t/data/zx48.rom', 0x101, 0x101);
is		$mem->peek(0x100),	undef;
is		$mem->peek(0x101),	0xD2;
is		$mem->peek(0x102),	0x41;
is		$mem->peek(0x3FFE),	0x42;
is		$mem->peek(0x3FFF),	0x3C;
is		$mem->peek(0x4000),	undef;
is		$mem->peek(0xFFFF),	undef;

isa_ok	$it = $mem->loaded_iter, 'CODE';
is_deeply [$it->()], [0x101, 0x3FFF];
is_deeply [$it->()], [];

#------------------------------------------------------------------------------
# load_file, at address, skip header, only some bytes
isa_ok $mem = CPU::Z80::Disassembler::Memory->new, 
		'CPU::Z80::Disassembler::Memory';

$mem->load_file('t/data/zx48.rom', 0x101, 0x101, 3);
is		$mem->peek(0x100),	undef;
is		$mem->peek(0x101),	0xD2;
is		$mem->peek(0x102),	0x41;
is		$mem->peek(0x103),	0x4E;
is		$mem->peek(0x104),	undef;

isa_ok	$it = $mem->loaded_iter, 'CODE';
is_deeply [$it->()], [0x101, 0x103];
is_deeply [$it->()], [];

#------------------------------------------------------------------------------
# peek - ranges
isa_ok 	$mem = CPU::Z80::Disassembler::Memory->new,
		'CPU::Z80::Disassembler::Memory';

isa_ok	$it = $mem->loaded_iter, 'CODE';
is_deeply [$it->()], [];

ok 1, "range test peek_str";

eval 	{ $mem->peek_str(-1, 10) };
like 	$@, qr/^address -0x01 out of range at t.*?Memory.t line \d+/;

eval 	{ $mem->peek_str(0, 0) };
like 	$@, qr/^invalid length 0 at t.*?Memory.t line \d+/;

is		$mem->peek_str(0, 10), undef;
is		$mem->peek_str(65535, 10), undef;

eval 	{ $mem->peek_str(65536, 10) };
like 	$@, qr/^address 0x10000 out of range at t.*?Memory.t line \d+/;


for my $func (qw(	peek 
					peek8u peek8s 
					peek16u peek16s 
					peek_strz peek_str7 )) {
	ok 1, "range test $func";
	
	eval 	{ $mem->$func(-1) };
	like 	$@, qr/^address -0x01 out of range at t.*?Memory.t line \d+/;

	is		$mem->$func(0), undef;
	is		$mem->$func(65535), undef;

	eval 	{ $mem->$func(65536) };
	like 	$@, qr/^address 0x10000 out of range at t.*?Memory.t line \d+/;
}

#------------------------------------------------------------------------------
# peek - numbers
isa_ok 	$mem = CPU::Z80::Disassembler::Memory->new,
		'CPU::Z80::Disassembler::Memory';
$mem->load_file('t/data/zx48.rom');

is		$mem->peek(  0x0255),	0x7F;
is		$mem->peek8u(0x0255),	0x7F;
is		$mem->peek8s(0x0255),	0x7F;

is		$mem->peek(  0x0397),	0x80;
is		$mem->peek8u(0x0397),	0x80;
is		$mem->peek8s(0x0397), -0x80;

is		$mem->peek(  0x4000),	undef;
is		$mem->peek8u(0x4000),	undef;
is		$mem->peek8s(0x4000),	undef;

# need to produce data for test
$mem->poke_str(0x4000, "\xff\x7f\x00\x80");

is		$mem->peek16u(0x4000),	0x7FFF;
is		$mem->peek16s(0x4000),	0x7FFF;

is		$mem->peek16u(0x4002),	0x8000;
is		$mem->peek16s(0x4002),-0x8000;

#------------------------------------------------------------------------------
# peek - strings
isa_ok 	$mem = CPU::Z80::Disassembler::Memory->new,
		'CPU::Z80::Disassembler::Memory';
$mem->load_file('t/data/zx48.rom');

is		$mem->peek_str(0x153B, 22), 	"1982 Sinclair Research";
is		$mem->peek_str(0x3FFF, 1), 		"<";
is		$mem->peek_str(0x3FFF, 2), 		undef;

is		$mem->peek_str7(0x153B),	 	"1982 Sinclair Research Ltd";
is		$mem->peek_str7(0x3FFF),	 	undef;

$mem->poke(0x153B + 22, 0);
is		$mem->peek_strz(0x153B),	 	"1982 Sinclair Research";
is		$mem->peek_strz(0x3FFF),	 	undef;

#------------------------------------------------------------------------------
# poke - ranges
isa_ok 	$mem = CPU::Z80::Disassembler::Memory->new,
		'CPU::Z80::Disassembler::Memory';

for my $func (qw(	poke 
					poke8u poke8s 
					poke16u poke16s 
					poke_str poke_strz poke_str7 )) {
	ok 1, "range test $func";
	
	eval 	{ $mem->$func(-1, 0) };
	like 	$@, qr/^address -0x01 out of range at t.*?Memory.t line \d+/;

	$mem->$func(0, 0);
	if ($func =~ /poke16|strz/) {
		$mem->$func(65534, 0);
	}
	else {
		$mem->$func(65535, 0);
	}

	eval 	{ $mem->$func(65536, 0) };
	like 	$@, qr/^address 0x10000 out of range at t.*?Memory.t line \d+/;
}

for my $func (qw( poke poke8u )) {
	ok 1, "range test $func";
	
	eval	{ $mem->$func(0, -1) };
	like 	$@, qr/^unsigned byte -0x01 out of range at t.*?Memory.t line \d+/;

	$mem->$func(0, 0);
	$mem->$func(0, 255);

	eval	{ $mem->$func(0, 256) };
	like 	$@, qr/^unsigned byte 0x100 out of range at t.*?Memory.t line \d+/;
}

eval	{ $mem->poke8s(0, -129) };
like 	$@, qr/^signed byte -0x81 out of range at t.*?Memory.t line \d+/;

$mem->poke8s(0, -128);
$mem->poke8s(0, 127);

eval	{ $mem->poke8s(0, 128) };
like 	$@, qr/^signed byte 0x80 out of range at t.*?Memory.t line \d+/;


eval	{ $mem->poke16u(0, -1) };
like 	$@, qr/^unsigned word -0x01 out of range at t.*?Memory.t line \d+/;

$mem->poke16u(0, 0);
$mem->poke16u(0, 65535);

eval	{ $mem->poke16u(0, 65536) };
like 	$@, qr/^unsigned word 0x10000 out of range at t.*?Memory.t line \d+/;


eval	{ $mem->poke16s(0, -32769) };
like 	$@, qr/^signed word -0x8001 out of range at t.*?Memory.t line \d+/;

$mem->poke16s(0, -32768);
$mem->poke16s(0, 32767);

eval	{ $mem->poke16s(0, 32768) };
like 	$@, qr/^signed word 0x8000 out of range at t.*?Memory.t line \d+/;

eval 	{ $mem->poke_strz(0, "hello".chr(0)) };
like 	$@, qr/^invalid zero character in string at t.*?Memory.t line \d+/;

eval 	{ $mem->poke_str7(0, "") };
like 	$@, qr/^invalid empty string at t.*?Memory.t line \d+/;

eval 	{ $mem->poke_str7(0, "hell".chr(128+ord("o"))) };
like 	$@, qr/^invalid bit-7 set character in string at t.*?Memory.t line \d+/;

#------------------------------------------------------------------------------
# poke - numbers
isa_ok 	$mem = CPU::Z80::Disassembler::Memory->new,
		'CPU::Z80::Disassembler::Memory';

for my $func (qw( poke poke8u poke8s )) {
	ok 1, "test $func";
	
	$mem->$func(0, 127);
	
	isa_ok	$it = $mem->loaded_iter, 'CODE';
	is_deeply [$it->()], [0,0];
	is_deeply [$it->()], [];

	is	$mem->peek_str(0, 1), chr(127);
}

for my $func (qw( poke16u poke16s )) {
	ok 1, "test $func";
	
	$mem->$func(0, 32767);
	
	isa_ok	$it = $mem->loaded_iter, 'CODE';
	is_deeply [$it->()], [0,1];
	is_deeply [$it->()], [];

	is	$mem->peek_str(0, 2), chr(255).chr(127);
}

#------------------------------------------------------------------------------
# poke - strings
isa_ok 	$mem = CPU::Z80::Disassembler::Memory->new,
		'CPU::Z80::Disassembler::Memory';

$mem->poke_strz(0, "");
isa_ok	$it = $mem->loaded_iter, 'CODE';
is_deeply [$it->()], [0,0];
is_deeply [$it->()], [];

is	$mem->peek_str(0, 1), chr(0);


$mem->poke_strz(0, "h");
isa_ok	$it = $mem->loaded_iter, 'CODE';
is_deeply [$it->()], [0,1];
is_deeply [$it->()], [];

is	$mem->peek_str(0, 2), "h".chr(0);


isa_ok 	$mem = CPU::Z80::Disassembler::Memory->new,
		'CPU::Z80::Disassembler::Memory';

$mem->poke_str7(0, "a");
isa_ok	$it = $mem->loaded_iter, 'CODE';
is_deeply [$it->()], [0,0];
is_deeply [$it->()], [];

is	$mem->peek_str(0, 1), chr(128+ord('a'));


$mem->poke_str7(0, "ab");
isa_ok	$it = $mem->loaded_iter, 'CODE';
is_deeply [$it->()], [0,1];
is_deeply [$it->()], [];

is	$mem->peek_str(0, 2), 'a'.chr(128+ord('b'));


done_testing;
