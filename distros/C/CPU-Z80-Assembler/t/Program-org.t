#!perl

# $Id$

use strict;
use warnings;

use Test::More tests => 205;

require_ok 't/test_utils.pl';

use_ok 'CPU::Z80::Assembler';
use_ok 'CPU::Z80::Assembler::Program';
use_ok 'CPU::Z80::Assembler::Segment';

my($program, $segment);

# one segment, one ORG
isa_ok $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';

is scalar(@{$program->child}), 0, "start with no segments";

$program->segment("CODE");
$program->org(10);
$program->add_opcodes(opcodes('A',1));

is scalar(@{$program->child}), 1, "one segments";

is $program->child->[0]->name, "CODE", "name";
is $program->child->[0], $program->segment("CODE"), "name";
is $program->child->[0]->address, 10, "name";

is $program->bytes, "ABC", "bytes";


# one segment, two ORG, no code in the middle
isa_ok $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';

is scalar(@{$program->child}), 0, "start with no segments";

$program->segment("CODE");
$program->org(10);
$program->org(20);
$program->add_opcodes(opcodes('A',1));

is scalar(@{$program->child}), 1, "one segments";

is $program->child->[0]->name, "CODE", "name";
is $program->child->[0], $program->segment("CODE"), "name";
is $program->child->[0]->address, 20, "name";

is $program->bytes, "ABC", "bytes";


# one segment, two ORG, code in the middle, no overlap
isa_ok $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';

is scalar(@{$program->child}), 0, "start with no segments";

$program->segment("CODE");
$program->org(10);
$program->add_opcodes(opcodes('A',1));
$program->org(13);
$program->add_opcodes(opcodes('a',1));

is scalar(@{$program->child}), 2, "two segments";

is $program->child->[0]->name, "CODE", "name";
is $program->child->[0], $program->segment("CODE"), "name";
is $program->child->[0]->address, 10, "name";

is $program->child->[1]->name, "CODE1", "name";
is $program->child->[1], $program->segment("CODE1"), "name";
is $program->child->[1]->address, 13, "name";

is $program->bytes, "ABCabc", "bytes";


# one segment, two ORG, code in the middle, gap
isa_ok $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';

is scalar(@{$program->child}), 0, "start with no segments";

$program->segment("CODE");
$program->org(10);
$program->add_opcodes(opcodes('A',1));
$program->org(16);
$program->add_opcodes(opcodes('a',1));

is scalar(@{$program->child}), 2, "two segments";

is $program->child->[0]->name, "CODE", "name";
is $program->child->[0], $program->segment("CODE"), "name";
is $program->child->[0]->address, 10, "name";

is $program->child->[1]->name, "CODE1", "name";
is $program->child->[1], $program->segment("CODE1"), "name";
is $program->child->[1]->address, 16, "name";

is $CPU::Z80::Assembler::fill_byte, 0xFF, "default fill byte";
is $program->bytes, "ABC\xFF\xFF\xFFabc", "bytes";

$CPU::Z80::Assembler::fill_byte = ord('!');
is $program->bytes, "ABC!!!abc", "bytes";


# one segment, two ORG, code in the middle, overlap
isa_ok $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';

is scalar(@{$program->child}), 0, "start with no segments";

$program->segment("CODE");
$program->org(10);
$program->add_opcodes(opcodes('A',1));
$program->org(11);
$program->add_opcodes(opcodes('a',3));

is scalar(@{$program->child}), 2, "two segments";

is $program->child->[0]->name, "CODE", "name";
is $program->child->[0], $program->segment("CODE"), "name";
is $program->child->[0]->address, 10, "name";

is $program->child->[1]->name, "CODE1", "name";
is $program->child->[1], $program->segment("CODE1"), "name";
is $program->child->[1]->address, 11, "name";

eval {$program->bytes};
is $@, "f.asm(3) : error: segments overlap, previous ends at 0x000D, next starts at 0x000B\n", "overlap";


# two segments, no ORG, no ORG
isa_ok $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';

is scalar(@{$program->child}), 0, "start with no segments";

$program->segment("CODE");
$program->add_opcodes(opcodes('A',1));
$program->segment("DATA");
$program->add_opcodes(opcodes('a',3));

is scalar(@{$program->child}), 2, "two segments";

$CPU::Z80::Assembler::fill_byte = ord('!');
is $program->bytes, "ABCabc", "bytes";

is $program->child->[0]->name, "CODE", "name";
is $program->child->[0], $program->segment("CODE"), "name";
is $program->child->[0]->address, 0, "name";

is $program->child->[1]->name, "DATA", "name";
is $program->child->[1], $program->segment("DATA"), "name";
is $program->child->[1]->address, 3, "name";


# two segments, ORG, no ORG
isa_ok $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';

is scalar(@{$program->child}), 0, "start with no segments";

$program->segment("CODE");
$program->org(10);
$program->add_opcodes(opcodes('A',1));
$program->segment("DATA");
$program->add_opcodes(opcodes('a',3));

is scalar(@{$program->child}), 2, "two segments";

$CPU::Z80::Assembler::fill_byte = ord('!');
is $program->bytes, "ABCabc", "bytes";

is $program->child->[0]->name, "CODE", "name";
is $program->child->[0], $program->segment("CODE"), "name";
is $program->child->[0]->address, 10, "name";

is $program->child->[1]->name, "DATA", "name";
is $program->child->[1], $program->segment("DATA"), "name";
is $program->child->[1]->address, 13, "name";


# two segments, no ORG, ORG
isa_ok $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';

is scalar(@{$program->child}), 0, "start with no segments";

$program->segment("CODE");
$program->add_opcodes(opcodes('A',1));
$program->segment("DATA");
$program->org(10);
$program->add_opcodes(opcodes('a',3));

is scalar(@{$program->child}), 2, "two segments";

$CPU::Z80::Assembler::fill_byte = ord('!');
is $program->bytes, "ABC!!!!!!!abc", "bytes";

is $program->child->[0]->name, "CODE", "name";
is $program->child->[0], $program->segment("CODE"), "name";
is $program->child->[0]->address, 0, "name";

is $program->child->[1]->name, "DATA", "name";
is $program->child->[1], $program->segment("DATA"), "name";
is $program->child->[1]->address, 10, "name";


# two segments, ORG, ORG
isa_ok $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';

is scalar(@{$program->child}), 0, "start with no segments";

$program->segment("CODE");
$program->org(10);
$program->add_opcodes(opcodes('A',1));
$program->segment("DATA");
$program->org(15);
$program->add_opcodes(opcodes('a',3));

is scalar(@{$program->child}), 2, "two segments";

$CPU::Z80::Assembler::fill_byte = ord('!');
is $program->bytes, "ABC!!abc", "bytes";

is $program->child->[0]->name, "CODE", "name";
is $program->child->[0], $program->segment("CODE"), "name";
is $program->child->[0]->address, 10, "name";

is $program->child->[1]->name, "DATA", "name";
is $program->child->[1], $program->segment("DATA"), "name";
is $program->child->[1]->address, 15, "name";

