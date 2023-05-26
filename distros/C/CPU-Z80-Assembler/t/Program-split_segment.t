#!perl

# $Id$

use strict;
use warnings;

use Test::More tests => 60;

require_ok 't/test_utils.pl';

use_ok 'CPU::Z80::Assembler::Program';
use_ok 'CPU::Z80::Assembler::Segment';


# split without segment
isa_ok my $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';

is scalar(@{$program->child}), 0, "start with no segments";

isa_ok my $segment = $program->split_segment, 'CPU::Z80::Assembler::Segment';
is scalar(@{$program->child}), 1, "one segments";
is $segment->name, "_", "name of empty segment";


# split one empty segment
isa_ok $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';

is scalar(@{$program->child}), 0, "start with no segments";

isa_ok $segment = $program->segment("CODE"), 'CPU::Z80::Assembler::Segment';
is scalar(@{$program->child}), 1, "one segments";
is $segment->name, "CODE", "name of empty segment";


# split one not-empty segment at the end of the list
isa_ok $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';

is scalar(@{$program->child}), 0, "start with no segments";

isa_ok $segment = $program->segment("CODE"), 'CPU::Z80::Assembler::Segment';
$program->add_opcodes(opcodes('A',1));

isa_ok $segment = $program->split_segment, 'CPU::Z80::Assembler::Segment';

is scalar(@{$program->child}), 2, "one segments";

is $segment->name, "CODE1", "name of empty segment";

is $program->child->[0]->name, "CODE", "name";
is $program->child->[0], $program->segment("CODE"), "name";

is $program->child->[1]->name, "CODE1", "name";
is $program->child->[1], $program->segment("CODE1"), "name";


# split one not-empty segment not at the end of the list
isa_ok $program = CPU::Z80::Assembler::Program->new,
		'CPU::Z80::Assembler::Program';

is scalar(@{$program->child}), 0, "start with no segments";

isa_ok $segment = $program->segment("CODE"), 'CPU::Z80::Assembler::Segment';
$program->add_opcodes(opcodes('A',1));

isa_ok $segment = $program->segment("DATA"), 'CPU::Z80::Assembler::Segment';
$program->add_opcodes(opcodes('A',1));

$program->segment("CODE");
isa_ok $segment = $program->split_segment, 'CPU::Z80::Assembler::Segment';

is scalar(@{$program->child}), 3, "three segments";

is $segment->name, "CODE1", "name of empty segment";

is $program->child->[0]->name, "CODE", "name";
is $program->child->[0], $program->segment("CODE"), "name";

is $program->child->[1]->name, "CODE1", "name";
is $program->child->[1], $program->segment("CODE1"), "name";

is $program->child->[2]->name, "DATA", "name";
is $program->child->[2], $program->segment("DATA"), "name";
