#!perl

# $Id$

use warnings;
use strict;

use Test::More;
use Data::Dump 'dump';

use_ok 'Asm::Preproc::Line';
use_ok 'CPU::Z80::Assembler';
use_ok 'Iterator::Simple::Lookahead';

require_ok 't/test_utils.pl';
our $stream;

isa_ok	$stream = z80preprocessor('include "t/data/include.z80"'),
		'Iterator::Simple::Lookahead';

test_line(	"NOP\n", 		1, 	't/data/include.z80');
test_line(	"NOP\n", 		2, 	't/data/include.z80');
test_eof();


eval {	z80preprocessor('include "NOFILE"')->next };
is		$@, "-(1) : error: unable to open input file 'NOFILE'\n", "include NOFILE";

isa_ok	$stream = z80preprocessor('include "t/data/include3.z80"'),
		'Iterator::Simple::Lookahead';

test_line(	"\tLD B,1\n", 	1,	't/data/include3.z80');
test_line(	"\tLD A,1\n", 	1, 	't/data/include2.z80');
test_line(	"NOP\n",		1, 	't/data/include.z80');
test_line(	"NOP\n", 		2, 	't/data/include.z80');
test_line(	"\tLD A,3\n", 	3, 	't/data/include2.z80');
test_line(	"NOP\n", 		1, 	't/data/include.z80');
test_line(	"NOP\n", 		2, 	't/data/include.z80');
test_line(	"\tLD A,5\n", 	5, 	't/data/include2.z80');
test_line(	"NOP\n", 		1, 	't/data/include.z80');
test_line(	"NOP\n", 		2, 	't/data/include.z80');
test_line(	"\tLD A,7\n", 	7, 	't/data/include2.z80');
test_line(	"NOP\n", 		1, 	't/data/include.z80');
test_line(	"NOP\n", 		2, 	't/data/include.z80');
test_line(	"\tLD A,8\n", 	9, 	't/data/include2.z80');
test_line(	"\tLD B,3\n", 	3, 	't/data/include3.z80');
test_eof();


isa_ok	$stream = z80preprocessor("%include 't/data/include.z80'"),
		'Iterator::Simple::Lookahead';

test_line(	"NOP\n", 		1, 	't/data/include.z80');
test_line(	"NOP\n", 		2, 	't/data/include.z80');
test_eof();


done_testing();
