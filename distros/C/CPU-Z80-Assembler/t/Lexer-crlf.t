#!perl

# $Id$

use warnings;
use strict;

use Test::More;

use_ok	'CPU::Z80::Assembler';
use_ok	'Iterator::Simple::Lookahead';

require_ok 't/test_utils.pl';
our $stream;


#------------------------------------------------------------------------------
# test handling of \r in Unix and Win systems
#------------------------------------------------------------------------------
isa_ok	$stream = z80lexer(" 1 \r 2 \r\n 3 \n 4"),
		'Iterator::Simple::Lookahead';

test_token_line(	" 1 \r 2\n", 1, "-");
test_token(	"NUMBER",  	1);
test_token(	"NUMBER",  	2);
test_token(	"\n", 		"\n");

test_token_line(	" 3\n", 2, "-");
test_token(	"NUMBER",  	3);
test_token(	"\n", 		"\n");

test_token_line(	" 4\n", 3, "-");
test_token(	"NUMBER",  	4);
test_token(	"\n", 		"\n");

test_eof();

done_testing();