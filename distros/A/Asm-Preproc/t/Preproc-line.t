#!perl

# $Id: Lexer-comments.t,v 1.6 2010/11/21 16:48:35 Paulo Exp $

use strict;
use warnings;

use Test::More;
use File::Slurp;

require_ok 't/utils.pl';

our $pp;

#------------------------------------------------------------------------------
# test %line
isa_ok $pp = Asm::Preproc->new, 'Asm::Preproc';
$pp->include_list(sub {<DATA>});
test_getline("line 1, no file\n", 		"-",		1);
test_getline("line 2, no file\n", 		"-",		2);
test_getline("line 3, no file\n", 		"-",		3);
test_getline("file.asm:1: line 1\n", 	"file.asm",	1);
test_getline("file.asm:2: line 2\n", 	"file.asm",	2);
test_getline("file.asm:3: line 1\n", 	"file.asm",	3);
test_getline("file.asm:3: line 2\n", 	"file.asm",	3);
test_getline("z.asm:8: line 8\n", 		"z.asm",	8);
test_getline("z.asm:9: line 9\n",		"z.asm",	9);
test_getline("z.asm:8: line 8\n", 		"z.asm",	8);
test_getline("z.asm:9: line 9\n",		"z.asm",	9);
test_getline("z.asm:25 25\n",			"z.asm",	25);
test_getline("z.asm:26 26\n",			"z.asm",	26);
test_getline("z.asm:45 x1\n",			"z.asm",	45);
test_getline("z.asm:45 x2\n",			"z.asm",	45);
test_eof();

done_testing();

__DATA__
line 1, no file
line 2, no file
line 3, no file
%line 1+1 file.asm
file.asm:1: line 1
file.asm:2: line 2
%line 3+0 "file.asm"
file.asm:3: line 1
file.asm:3: line 2
#line 8 "z.asm"
z.asm:8: line 8
z.asm:9: line 9
%line 8 z.asm
z.asm:8: line 8
z.asm:9: line 9
%line 25
z.asm:25 25
z.asm:26 26
%line 45+0
z.asm:45 x1
z.asm:45 x2
