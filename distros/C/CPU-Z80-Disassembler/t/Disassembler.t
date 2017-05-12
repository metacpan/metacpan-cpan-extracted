#!perl

use strict;
use warnings;

BEGIN { use lib 't/tools' }
use TestAsm;

use Test::More;
use File::Slurp;
use Test::Output 'stdout_from';

use CPU::Z80::Disassembler;	# use_ok does not import symbols?!

my $dis;
my $ok;
my $fh;
my $stdout;

my $rom_input = 't/data/zx48.rom';

my $dump_output = 'zx48.dump';
my $dump_benchmark = 't/data/zx48_benchmark.dump';

my $asm_output = 'zx48.asm';
my $asm_benchmark = 't/data/zx48_benchmark.asm';


#------------------------------------------------------------------------------
# set_type_*
isa_ok $dis = CPU::Z80::Disassembler->new, 'CPU::Z80::Disassembler';
$dis->memory->load_file($rom_input);

eval	{ $dis->set_type_code(0x4000) };
like	$@, qr/^Getting type of unloaded memory at 0x4000 at t.*Disassembler.t line \d+/;

is		$dis->get_type(0),		TYPE_UNKNOWN;

$dis->set_type_code(0);
is		$dis->get_type(0),		TYPE_CODE;
is		$dis->get_type(1),		TYPE_UNKNOWN;
is		$dis->get_type(3),		TYPE_UNKNOWN;

$dis->set_type_code(0, 2);
is		$dis->get_type(0),		TYPE_CODE;
is		$dis->get_type(1),		TYPE_CODE;
is		$dis->get_type(3),		TYPE_UNKNOWN;

eval	{ $dis->set_type_byte(0) };
like	$@, qr/^Changing type of address 0x0000 from C to B at t.*Disassembler.t line \d+/;

#------------------------------------------------------------------------------
# line_comments
isa_ok $dis = CPU::Z80::Disassembler->new, 'CPU::Z80::Disassembler';
$dis->memory->load_file($rom_input);

eval 	{ $dis->line_comments(0x1000, 'hello') };
like	$@, qr/^Cannot set comment of unknown instruction at 0x1000 at t.*Disassembler.t line \d+/;

#------------------------------------------------------------------------------
# relative_arg
isa_ok $dis = CPU::Z80::Disassembler->new, 'CPU::Z80::Disassembler';
$dis->memory->load_file($rom_input);

eval 	{ $dis->relative_arg(0x0000, 'START') };
like	$@, qr/^Label 'START' not found at t.*Disassembler.t line \d+/;

$dis->labels->add(0xFF00, 'START');

eval 	{ $dis->relative_arg(0x0000, 'START') };
like	$@, qr/^Instruction at address 0x0000 has no arguments at t.*Disassembler.t line \d+/;

is $dis->instr->[0x0002]->as_string, 'ld de,0xFFFF';

$dis->relative_arg(0x0002, 'START');
is $dis->instr->[0x0002]->as_string, 'ld de,START+0xFF';

$dis->instr->[0x0002]->NN(0xFF00);
$dis->relative_arg(0x0002, 'START');
is $dis->instr->[0x0002]->as_string, 'ld de,START';

$dis->instr->[0x0002]->NN(0xF000);
$dis->relative_arg(0x0002, 'START');
is $dis->instr->[0x0002]->as_string, 'ld de,START-0xF00';

$dis->instr->[0x0002]->NN(0x0000);
$dis->relative_arg(0x0002, '$');
is $dis->instr->[0x0002]->as_string, 'ld de,$-0x02';

$dis->instr->[0x0002]->NN(0x0002);
$dis->relative_arg(0x0002, '$');
is $dis->instr->[0x0002]->as_string, 'ld de,$';

$dis->instr->[0x0002]->NN(0x0004);
$dis->relative_arg(0x0002, '$');
is $dis->instr->[0x0002]->as_string, 'ld de,$+0x02';

$dis->code(0x028E);
is $dis->instr->[0x028E]->as_string, 'ld l,0x2F';

$dis->relative_arg(0x028E, 'START');
is $dis->instr->[0x028E]->as_string, 'ld l,START-0xFED1';

$dis->labels->add(0x002F, 'L1');
$dis->relative_arg(0x028E, 'L1');
is $dis->instr->[0x028E]->as_string, 'ld l,L1';

$dis->labels->add(0x0030, 'L2');
$dis->relative_arg(0x028E, 'L2');
is $dis->instr->[0x028E]->as_string, 'ld l,L2-0x01';

$dis->labels->add(0x002E, 'L3');
$dis->relative_arg(0x028E, 'L3');
is $dis->instr->[0x028E]->as_string, 'ld l,L3+0x01';

#------------------------------------------------------------------------------
# write_dump - empty
isa_ok $dis = CPU::Z80::Disassembler->new, 'CPU::Z80::Disassembler';

$stdout = stdout_from(sub {$dis->write_dump});
ok lines_equal($stdout, ""), "$dump_output : empty";

$dis->write_dump($dump_output);
$ok = lines_equal("", scalar(read_file($dump_output)));
ok $ok, "$dump_output : empty";
unlink $dump_output if ($ok && ! $ENV{DEBUG});

#------------------------------------------------------------------------------
# write_dump - with file
isa_ok $dis = CPU::Z80::Disassembler->new, 'CPU::Z80::Disassembler';
$dis->memory->load_file($rom_input);

$stdout = stdout_from(sub {$dis->write_dump});
ok lines_equal($stdout, scalar(read_file($dump_benchmark))), 
		"$dump_benchmark $dump_output : equal";

$dis->write_dump($dump_output);
$ok = lines_equal(scalar(read_file($dump_benchmark)), 
				  scalar(read_file($dump_output)));
ok $ok, "$dump_benchmark $dump_output : equal";
unlink $dump_output if ($ok && ! $ENV{DEBUG});

#------------------------------------------------------------------------------
# write_asm - empty
isa_ok $dis = CPU::Z80::Disassembler->new, 'CPU::Z80::Disassembler';

$stdout = stdout_from(sub {$dis->write_asm});
ok lines_equal($stdout, ""), "$asm_output : empty";

$dis->write_asm($asm_output);
$ok = lines_equal("", scalar(read_file($asm_output)));
ok $ok, "$asm_output : empty";
unlink $asm_output if ($ok && ! $ENV{DEBUG});

#------------------------------------------------------------------------------
# write_asm - with file partially disassembled
isa_ok $dis = CPU::Z80::Disassembler->new, 'CPU::Z80::Disassembler';
$dis->memory->load_file($rom_input);
$dis->code(0, 'START');
$dis->write_asm($asm_output);
test_assembly($asm_output, $rom_input);
unlink $asm_output if ($ok && ! $ENV{DEBUG});

done_testing();

