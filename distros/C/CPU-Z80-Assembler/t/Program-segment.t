#!perl

# $Id$

use strict;
use warnings;

use Test::More tests => 86;

require_ok 't/test_utils.pl';

use_ok 'CPU::Z80::Assembler::Program';
use_ok 'CPU::Z80::Assembler::Segment';


# empty start
isa_ok my $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';
is scalar(@{$program->child}), 0, "start with no segments";
isa_ok my $segment = $program->segment, 'CPU::Z80::Assembler::Segment';
is scalar(@{$program->child}), 1, "one segments";
is $segment->name, "_", "name of empty segment";


# empty start, add bytes
isa_ok $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';
		
is scalar(@{$program->child}), 0, "start with no segments";

$program->add_opcodes(opcodes('A', 1));
is scalar(@{$program->child}), 1, "one segments";

isa_ok $segment = $program->segment, 'CPU::Z80::Assembler::Segment';
is $program->child->[0], $segment, "segment";

is $segment->name, "_", "name of empty segment";
is $program->bytes, "ABC", "bytes";
is $segment->line->text, "line 1\n", "segment line text";
is $segment->line->line_nr, 1, "segment line text";
is $segment->line->file, "f.asm", "segment line text";
is $segment->address, 0, "start address";


# empty start, add bytes to two segments, alternate
isa_ok $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';
		
is scalar(@{$program->child}), 0, "start with no segments";

isa_ok $segment = $program->segment("CODE"), 'CPU::Z80::Assembler::Segment';
is $program->child->[0], $segment, "segment";
is $program->child->[0], $program->segment, "segment";

isa_ok $segment = $program->segment("DATA"), 'CPU::Z80::Assembler::Segment';
is $program->child->[1], $segment, "segment";
is $program->child->[1], $program->segment, "segment";

$program->add_opcodes(opcodes('D',3));

isa_ok $segment = $program->segment("CODE"), 'CPU::Z80::Assembler::Segment';
is $program->child->[0], $segment, "segment";
is $program->child->[0], $program->segment, "segment";

$program->add_opcodes(opcodes('C',1));

isa_ok $segment = $program->segment("DATA"), 'CPU::Z80::Assembler::Segment';
is $program->child->[1], $segment, "segment";
is $program->child->[1], $program->segment, "segment";

$program->add_opcodes(opcodes('d',30));

isa_ok $segment = $program->segment("CODE"), 'CPU::Z80::Assembler::Segment';
is $program->child->[0], $segment, "segment";
is $program->child->[0], $program->segment, "segment";

$program->add_opcodes(opcodes('c',10));

is scalar(@{$program->child}), 2, "two segments";

is $program->bytes, "CDEcdeDEFdef", "bytes";

is $program->child->[0]->name, "CODE", "name of empty segment";
is $program->child->[0]->address, 0, "segment address";
is $program->child->[0]->line->text, "line 1\n", "segment line text";
is $program->child->[0]->line->line_nr, 1, "segment line text";
is $program->child->[0]->line->file, "f.asm", "segment line text";

is $program->child->[1]->name, "DATA", "name of empty segment";
is $program->child->[1]->address, 6, "segment address";
is $program->child->[1]->line->text, "line 3\n", "segment line text";
is $program->child->[1]->line->line_nr, 3, "segment line text";
is $program->child->[1]->line->file, "f.asm", "segment line text";
