#!perl

# $Id$

use warnings;
use strict;

use Test::More;

use_ok	'CPU::Z80::Assembler';
use_ok	'Iterator::Simple::Lookahead';

require_ok 't/test_utils.pl';
our $stream;


isa_ok	$stream = z80lexer("%include 't/data/include3.z80'\n"),
		'Iterator::Simple::Lookahead';

test_token_line(	"\tLD B,1\n", 1, 't/data/include3.z80');
test_token(	"ld", 		"ld");
test_token(	"b",  		"b");
test_token(	",",  		",");
test_token(	"NUMBER",  	"1");
test_token(	"\n", 		"\n");

test_token_line(	"\tLD A,1\n", 1, 't/data/include2.z80');
test_token(	"ld", 		"ld");
test_token(	"a",  		"a");
test_token(	",",  		",");
test_token(	"NUMBER",  	"1");
test_token(	"\n", 		"\n");

test_token_line(	"NOP\n", 1, 't/data/include.z80');
test_token(	"nop", 		"nop");
test_token(	"\n", 		"\n");

test_token_line(	"NOP\n", 2, 't/data/include.z80');
test_token(	"nop", 		"nop");
test_token(	"\n", 		"\n");

test_token_line(	"\tLD A,3\n", 3, 't/data/include2.z80');
test_token(	"ld", 		"ld");
test_token(	"a",  		"a");
test_token(	",",  		",");
test_token(	"NUMBER",  	"3");
test_token(	"\n", 		"\n");

test_token_line(	"NOP\n", 1, 't/data/include.z80');
test_token(	"nop", 		"nop");
test_token(	"\n", 		"\n");

test_token_line(	"NOP\n", 2, 't/data/include.z80');
test_token(	"nop", 		"nop");
test_token(	"\n", 		"\n");

test_token_line(	"\tLD A,5\n", 5, 't/data/include2.z80');
test_token(	"ld", 		"ld");
test_token(	"a",  		"a");
test_token(	",",  		",");
test_token(	"NUMBER",  	"5");
test_token(	"\n", 		"\n");

test_token_line(	"NOP\n", 1, 't/data/include.z80');
test_token(	"nop", 		"nop");
test_token(	"\n", 		"\n");

test_token_line(	"NOP\n", 2, 't/data/include.z80');
test_token(	"nop", 		"nop");
test_token(	"\n", 		"\n");

test_token_line(	"\tLD A,7\n", 7, 't/data/include2.z80');
test_token(	"ld", 		"ld");
test_token(	"a",  		"a");
test_token(	",",  		",");
test_token(	"NUMBER",  	"7");
test_token(	"\n", 		"\n");

test_token_line(	"NOP\n", 1, 't/data/include.z80');
test_token(	"nop", 		"nop");
test_token(	"\n", 		"\n");

test_token_line(	"NOP\n", 2, 't/data/include.z80');
test_token(	"nop", 		"nop");
test_token(	"\n", 		"\n");

test_token_line(	"\tLD A,8\n", 9, 't/data/include2.z80');
test_token(	"ld", 		"ld");
test_token(	"a",  		"a");
test_token(	",",  		",");
test_token(	"NUMBER",  	"8");
test_token(	"\n", 		"\n");

test_token_line(	"\tLD B,3\n", 3, 't/data/include3.z80');
test_token(	"ld", 		"ld");
test_token(	"b",  		"b");
test_token(	",",  		",");
test_token(	"NUMBER",  	"3");
test_token(	"\n", 		"\n");

test_eof();


isa_ok	$stream = z80lexer("%include 't/data/include.z80'"),
		'Iterator::Simple::Lookahead';

test_token_line(	"NOP\n", 1, 't/data/include.z80');
test_token(	"nop", 		"nop");
test_token(	"\n", 		"\n");

test_token_line(	"NOP\n", 2, 't/data/include.z80');
test_token(	"nop", 		"nop");
test_token(	"\n", 		"\n");

test_eof();


done_testing();
