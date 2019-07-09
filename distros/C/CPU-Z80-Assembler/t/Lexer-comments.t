#!perl

# $Id$

use warnings;
use strict;

use Test::More;

use_ok	'CPU::Z80::Assembler';
use_ok	'Iterator::Simple::Lookahead';

require_ok 't/test_utils.pl';
our $stream;


isa_ok	$stream = z80lexer("23;comment\n"),
		'Iterator::Simple::Lookahead';

test_token_line(	"23;comment\n", 1, "-");
test_token(	"NUMBER",  	"23");
test_token(	"\n", 		"\n");
test_eof();


isa_ok	$stream = z80lexer("23;comment"),
		'Iterator::Simple::Lookahead';

test_token_line(	"23;comment\n", 1, "-");
test_token(	"NUMBER",  	"23");
test_token(	"\n", 		"\n");
test_eof();


is		z80lexer("#define 23")->next, undef, "end of input";
is		z80lexer(" #define 23")->next, undef, "end of input";
is		z80lexer(" # define 23")->next, undef, "end of input";

is		z80lexer("#define 23\n")->next, undef, "end of input";
is		z80lexer(" #define 23\n")->next, undef, "end of input";
is		z80lexer(" # define 23\n")->next, undef, "end of input";

done_testing();