#!perl

use strict;
use warnings;

use Test::More;

use_ok 'CPU::Z80::Disassembler::Instruction';

my $mem;
my $instr;

#------------------------------------------------------------------------------
# test one instruction
sub t_instr (@) {
	my($factory, $addr, $limit, $size, $opcode, $args, 
	   $is_call, $is_branch, $is_break_flow,
	   $string, $dump) = @_;
	
	my $caller_line = (caller)[2];
	ok 1, "[line $caller_line]";

	isa_ok $instr = CPU::Z80::Disassembler::Instruction->$factory(
												$mem, $addr, $limit), 
			'CPU::Z80::Disassembler::Instruction';

	is $instr->memory, 	$mem, 		"memory";
	is $instr->addr, 	$addr, 		"addr = $addr";
	is $instr->size, 	$size, 		"size = $size";
	is $instr->opcode, 	$opcode, 	"opcode = $opcode";
	is !!$instr->is_code, !!($opcode !~ /def|org/), "is_code = ".
									(!!$instr->is_code);
	
	for my $arg (qw( N NN DIS STR )) {
		ok exists($args->{$arg}) ? 
				_list_str($args->{$arg}) eq _list_str($instr->$arg) :
				!defined($instr->$arg),	
			"$arg = ".(exists($args->{$arg}) ? 
							_list_str($args->{$arg}) : 
							'undef');
	}
	
	is $instr->next_addr,	$addr+$size,	"next_addr";

	my @next_code;
	push @next_code, $instr->NN if $instr->opcode =~ /jr|jp .*NN|djnz|call|rst/;
	push @next_code, $instr->next_addr unless $instr->opcode =~ /ret$|reti|retn|jp NN|jr NN|call NN|rst|jp \(|org/;
	is_deeply [$instr->next_code], \@next_code;
	
	my $bytes = [];
	for (0 .. $size-1) {
		push @$bytes, $mem->peek($addr+$_);
	}
	is_deeply $instr->bytes,	$bytes,		"bytes = @$bytes";
	
	is !!$instr->is_call,		!!$is_call,	
									"is_call = $is_call";
	is !!$instr->is_branch,		!!$is_branch,
									"is_branch = $is_branch";
	is !!$instr->is_break_flow,	!!$is_break_flow,
									"is_break_flow = $is_break_flow";
	
	is $instr->as_string,	$string,	"as_string = $string";
	is $instr->dump,		$dump,		"dump = \n$dump";
	
	my $asm = " " x 8 . $string . "\n";
	$asm .= "\n" if $opcode =~ /jp NN|jp \(|jr NN|ret[in]?$|org/;
	is $instr->asm,			$asm,		"asm = \n$asm";
	
}

sub _list_str {
	my($v) = @_;
	ref($v) ? join(",", @$v) : $v;
}


#------------------------------------------------------------------------------
isa_ok $mem = CPU::Z80::Disassembler::Memory->new, 
			'CPU::Z80::Disassembler::Memory';
$mem->load_file('t/data/zx48.rom');

#------------------------------------------------------------------------------
# disassemble - undef 1st byte
is $instr = CPU::Z80::Disassembler::Instruction->disassemble($mem, 0x4000), 
			undef;

#------------------------------------------------------------------------------
# disassemble - undef 2nd byte
isa_ok $mem = CPU::Z80::Disassembler::Memory->new, 
			'CPU::Z80::Disassembler::Memory';
$mem->load_file('t/data/zx48.rom', 0, 0, 3);

is $instr = CPU::Z80::Disassembler::Instruction->disassemble($mem, 2), 
			undef;

isa_ok $mem = CPU::Z80::Disassembler::Memory->new, 
			'CPU::Z80::Disassembler::Memory';
$mem->load_file('t/data/zx48.rom');

#------------------------------------------------------------------------------
# disassemble - invalid opcode
is $instr = CPU::Z80::Disassembler::Instruction->disassemble($mem, 0x1A88), 
			undef;

#------------------------------------------------------------------------------
# disassemble

# no args
t_instr	disassemble => 0x0000,	undef,
				1,	'di',		{}, 				0, 0, 0, 
					"di",
	"0000 F3         di\n";

# N
t_instr	disassemble => 0x107,	undef,
				2,	'ld a,N',	{N => 0xBD}, 		0, 0, 0, 
					"ld a,0xBD",
	"0107 3EBD       ld a,0xBD\n";

# NN
t_instr	disassemble => 0x0002,	undef,
				3,	'ld de,NN',	{NN => 0xFFFF}, 	0, 0, 0, 
					"ld de,0xFFFF",
	"0002 11FFFF     ld de,0xFFFF\n";

# DIS < 0
t_instr	disassemble => 0x0F3E,	undef,
				3,	'ld e,(iy+DIS)', {DIS => -1}, 	0, 0, 0, 
					"ld e,(iy-0x01)",
	"0F3E FD5EFF     ld e,(iy-0x01)\n";

# DIS == 0
t_instr	disassemble => 0x0055,	undef,
				3,	'ld (iy+DIS),l', {DIS => 0}, 	0, 0, 0, 
					"ld (iy),l",
	"0055 FD7500     ld (iy),l\n";

# DIS > 0
t_instr	disassemble => 0x0045,	undef,
				3,	'inc (iy+DIS)', {DIS => 64}, 	0, 0, 0, 
					"inc (iy+0x40)",
	"0045 FD3440     inc (iy+0x40)\n";

# jump relative backwards
t_instr	disassemble => 0x062B,	undef,
				2,	'djnz NN', {NN => 0x0629}, 		0, 1, 0, 
					"djnz 0x0629",
	"062B 10FC       djnz 0x0629\n";

# jump jump relative forwards
t_instr	disassemble => 0x0043,	undef,
				2,	'jr nz,NN', {NN => 0x0048}, 	0, 1, 0, 
					"jr nz,0x0048",
	"0043 2003       jr nz,0x0048\n";

# inconditional relative jump 
t_instr	disassemble => 0x000E,	undef,
				2,	'jr NN', {NN => 0x0053}, 		0, 1, 1, 
					"jr 0x0053",
	"000E 1843       jr 0x0053\n";

# inconditional absolute jump 
t_instr	disassemble => 0x0005,	undef,
				3,	'jp NN', {NN => 0x11CB}, 		0, 1, 1, 
					"jp 0x11CB",
	"0005 C3CB11     jp 0x11CB\n";

# conditional absolute jump 
t_instr	disassemble => 0x00B2,	undef,
				3,	'jp nc,NN', {NN => 0xD441}, 	0, 1, 0, 
					"jp nc,0xD441",
	"00B2 D241D4     jp nc,0xD441\n";

# register jump 
t_instr	disassemble => 0x006F,	undef,
				1,	'jp (hl)', {}, 					0, 0, 1, 
					"jp (hl)",
	"006F E9         jp (hl)\n";

# rst
t_instr	disassemble => 0x0114,	undef,
				1,	'rst N', {N => 8, NN => 8},		1, 1, 1, 
					"rst 0x08",
	"0114 CF         rst 0x08\n";

# inconditional call 
t_instr	disassemble => 0x001C,	undef,
				3,	'call NN', {NN => 0x007D}, 		1, 1, 1, 
					"call 0x007D",
	"001C CD7D00     call 0x007D\n";

# conditional call 
t_instr	disassemble => 0x0098,	undef,
				3,	'call nz,NN', {NN => 0x4E49}, 	1, 1, 0, 
					"call nz,0x4E49",
	"0098 C4494E     call nz,0x4E49\n";

# inconditional ret 
t_instr	disassemble => 0x0052,	undef,
				1,	'ret', {},				 		0, 0, 1, 
					"ret",
	"0052 C9         ret\n";

# conditional ret 
t_instr	disassemble => 0x001F,	undef,
				1,	'ret nc', {}, 					0, 0, 0, 
					"ret nc",
	"001F D0         ret nc\n";

# retn
t_instr	disassemble => 0x0072,	undef,
				2,	'retn', {},				 		0, 0, 1, 
					"retn",
	"0072 ED45       retn\n";

# reti
$mem->poke(0x0073, 0x4D);
t_instr	disassemble => 0x0072,	undef,
				2,	'reti', {},				 		0, 0, 1, 
					"reti",
	"0072 ED4D       reti\n";
$mem->poke(0x0073, 0x45);

# composed instr with DIS+1 - decode smallest
for my $limit (undef, 0x702 .. 0x704) {
	ok 1, "limit ".(defined $limit ? sprintf("%04X", $limit) : 'undef');
	
	t_instr	disassemble => 0x06FF,	$limit,
					3,	'ld (ix+DIS),c', {DIS => 11}, 	0, 0, 0, 
						"ld (ix+0x0B),c",
		"06FF DD710B     ld (ix+0x0B),c\n";
}

# composed instr with DIS+1 - decode biggest
for my $limit (-1, 0x6FF .. 0x701, 0x705) {
	ok 1, "limit ".(defined $limit ? sprintf("%04X", $limit) : 'undef');
	
	t_instr	disassemble => 0x06FF,	$limit,
					6,	'ld (ix+DIS),bc', {DIS => 11}, 	0, 0, 0, 
						"ld (ix+0x0B),bc",
		"06FF DD710BDD70 ld (ix+0x0B),bc\n".
		"     0C         \n";
}
	
# defb
is $instr = CPU::Z80::Disassembler::Instruction->defb($mem, 0x4000), 
			undef;
is $instr = CPU::Z80::Disassembler::Instruction->defb($mem, 0x3FFF, 2), 
			undef;
t_instr	defb => 0,		undef,
				1,	'defb N', {N => 0xF3}, 			0, 0, 0, 
					"defb 0xF3",
	"0000 F3         defb 0xF3\n";

t_instr	defb => 0,		1,
				1,	'defb N', {N => 0xF3}, 			0, 0, 0, 
					"defb 0xF3",
	"0000 F3         defb 0xF3\n";

t_instr	defb => 0,		2,
				2,	'defb N', {N => [0xF3,0xAF]},	0, 0, 0, 
					"defb 0xF3,0xAF",
	"0000 F3AF       defb 0xF3,0xAF\n";

t_instr	defb => 0,		8,
				8,	'defb N', {N => [0xF3,0xAF,0x11,0xFF,0xFF,0xC3,0xCB,0x11]},
													0, 0, 0, 
					"defb 0xF3,0xAF,0x11,0xFF,0xFF,0xC3,0xCB,0x11",
	"0000 F3AF11FFFF defb 0xF3,0xAF,0x11,0xFF,0xFF,0xC3,0xCB,0x11\n".
	"     C3CB11     \n";

# defw
is $instr = CPU::Z80::Disassembler::Instruction->defw($mem, 0x4000), 
			undef;
is $instr = CPU::Z80::Disassembler::Instruction->defw($mem, 0x3FFF), 
			undef;
is $instr = CPU::Z80::Disassembler::Instruction->defw($mem, 0x4000-3, 2), 
			undef;

t_instr	defw => 0x3FFE,		undef,
				2,	'defw NN', {NN => 0x3C42},		0, 0, 0, 
					"defw 0x3C42",
	"3FFE 423C       defw 0x3C42\n";

t_instr	defw => 0x3FFE,		1,
				2,	'defw NN', {NN => 0x3C42},		0, 0, 0, 
					"defw 0x3C42",
	"3FFE 423C       defw 0x3C42\n";

t_instr	defw => 0,		4,
				8,	'defw NN', {NN => [0xAFF3,0xFF11,0xC3FF,0x11CB]},
													0, 0, 0, 
					"defw 0xAFF3,0xFF11,0xC3FF,0x11CB",
	"0000 F3AF11FFFF defw 0xAFF3,0xFF11,0xC3FF,0x11CB\n".
	"     C3CB11     \n";

# defm
is $instr = CPU::Z80::Disassembler::Instruction->defm($mem, 0x4000, 2), 
			undef;
is $instr = CPU::Z80::Disassembler::Instruction->defm($mem, 0x3FFF, 2), 
			undef;
t_instr	defm => 0x153B, 	22,
				22,	'defm STR', {STR => "1982 Sinclair Research"}, 0, 0, 0, 
					"defm '1982 Sinclair Research'",
	"153B 3139383220 defm '1982 Sinclair Research'\n".
	"     53696E636C \n".
	"     6169722052 \n".
	"     6573656172 \n".
	"     6368       \n";

# defm7
is $instr = CPU::Z80::Disassembler::Instruction->defm7($mem, 0x4000), 
			undef;
is $instr = CPU::Z80::Disassembler::Instruction->defm7($mem, 0x3FFF), 
			undef;
t_instr	defm7 => 0x153B, 	undef,
				26,	'defm7 STR', {STR => "1982 Sinclair Research Ltd"}, 0, 0, 0, 
					"defm7 '1982 Sinclair Research Ltd'",
	"153B 3139383220 defm7 '1982 Sinclair Research Ltd'\n".
	"     53696E636C \n".
	"     6169722052 \n".
	"     6573656172 \n".
	"     6368204C74 \n".
	"     E4         \n";

# defmz
is $instr = CPU::Z80::Disassembler::Instruction->defmz($mem, 0x4000), 
			undef;
is $instr = CPU::Z80::Disassembler::Instruction->defmz($mem, 0x3FFF), 
			undef;

$mem->poke(0x153B + 22, 0);		# create a zero-terminated string
t_instr	defmz => 0x153B, 	undef,
				23,	'defmz STR', {STR => "1982 Sinclair Research"}, 0, 0, 0, 
					"defmz '1982 Sinclair Research'",
	"153B 3139383220 defmz '1982 Sinclair Research'\n".
	"     53696E636C \n".
	"     6169722052 \n".
	"     6573656172 \n".
	"     636800     \n";

# org
t_instr	org => 0x8000,		undef,
				0,	'org NN', {NN => 0x8000}, 			0, 0, 1, 
					"org 0x8000",
	"8000            org 0x8000\n";

#------------------------------------------------------------------------------
# format

# N
isa_ok	$instr = CPU::Z80::Disassembler::Instruction->disassemble(
												$mem, 0x107), 
			'CPU::Z80::Disassembler::Instruction';
is		$instr->as_string,	"ld a,0xBD";
$instr->format->{N} = sub { shift };
is		$instr->as_string,	"ld a," . 0xBD;
$instr->format->{N} = sub { 'VAR' };
is		$instr->as_string,	"ld a,VAR";

# NN
isa_ok	$instr = CPU::Z80::Disassembler::Instruction->disassemble(
												$mem, 0x0002), 
			'CPU::Z80::Disassembler::Instruction';
is		$instr->as_string,	"ld de,0xFFFF";
$instr->format->{NN} = sub { shift };
is		$instr->as_string,	"ld de," . 0xFFFF;
$instr->format->{NN} = sub { 'VAR' };
is		$instr->as_string,	"ld de,VAR";

# DIS < 0
isa_ok	$instr = CPU::Z80::Disassembler::Instruction->disassemble(
												$mem, 0x0F3E), 
			'CPU::Z80::Disassembler::Instruction';
is		$instr->as_string,	"ld e,(iy-0x01)";
$instr->format->{DIS} = sub { sprintf("%+d", shift) };
is		$instr->as_string,	"ld e,(iy-1)";
$instr->format->{DIS} = sub { '+VAR-BASE' };
is		$instr->as_string,	"ld e,(iy+VAR-BASE)";

# DIS == 0
isa_ok	$instr = CPU::Z80::Disassembler::Instruction->disassemble(
												$mem, 0x0055), 
			'CPU::Z80::Disassembler::Instruction';
is		$instr->as_string,	"ld (iy),l";
$instr->format->{DIS} = sub { sprintf("%+d", shift) };
is		$instr->as_string,	"ld (iy+0),l";
$instr->format->{DIS} = sub { '+VAR-BASE' };
is		$instr->as_string,	"ld (iy+VAR-BASE),l";

# DIS > 0
isa_ok	$instr = CPU::Z80::Disassembler::Instruction->disassemble(
												$mem, 0x0045), 
			'CPU::Z80::Disassembler::Instruction';
is		$instr->as_string,	"inc (iy+0x40)";
$instr->format->{DIS} = sub { sprintf("%+d", shift) };
is		$instr->as_string,	"inc (iy+64)";
$instr->format->{DIS} = sub { '+VAR-BASE' };
is		$instr->as_string,	"inc (iy+VAR-BASE)";

# STR
isa_ok	$instr = CPU::Z80::Disassembler::Instruction->defm(
												$mem, 0x153B, 22), 
			'CPU::Z80::Disassembler::Instruction';
is		$instr->as_string,	"defm '1982 Sinclair Research'";
$instr->format->{STR} = sub { '"'.(shift).'"' };
is		$instr->as_string,	'defm "1982 Sinclair Research"';
$instr->format->{STR} = sub { 'STR' };
is		$instr->as_string,	"defm STR";


#------------------------------------------------------------------------------
# comment
isa_ok	$instr = CPU::Z80::Disassembler::Instruction->disassemble($mem, 0), 
			'CPU::Z80::Disassembler::Instruction';

is		$instr->as_string,	'di';

$instr->comment("Disable interrupts");
is		$instr->as_string,	'di'. ' ' x 22 . '; Disable interrupts';

$instr->opcode('x' x 24);
is		$instr->as_string,	'x' x 24 . "\n" . ' ' x 32 . '; Disable interrupts';

$instr->opcode('di');
$instr->comment("Disable\ninterrupts");
is		$instr->as_string,	'di'. ' ' x 22 . "; Disable\n" . 
								  ' ' x 32 . "; interrupts";

$instr->opcode('x' x 24);
is		$instr->as_string,	'x' x 24 . "\n" . 
								  ' ' x 32 . "; Disable\n" . 
								  ' ' x 32 . "; interrupts";



done_testing;
