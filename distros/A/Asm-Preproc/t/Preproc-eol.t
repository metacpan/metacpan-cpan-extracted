#!perl

# $Id: Lexer-comments.t,v 1.6 2010/11/21 16:48:35 Paulo Exp $

use strict;
use warnings;

use Test::More;
use File::Slurp;

require_ok 't/utils.pl';

our $pp;

#------------------------------------------------------------------------------
# test eol normalization and joining continuation lines
my @input = ("1\r\n",
			 "2\n",
			 "3",
			 "4a\\\r\n",
			 "4b\\\n",
			 "4c\\ ",		# back-slash only joins if at end of line
			 "5a\\",
			 "5b\\\n",
			 "5c\r\n",
			 "6\\");
isa_ok $pp = Asm::Preproc->new, 'Asm::Preproc';
$pp->include_list(@input);
test_getline("1\n", 			"-", 	1);
test_getline("2\n", 			"-", 	2);
test_getline("3\n", 			"-", 	3);
test_getline("4a 4b 4c\\\n", 	"-", 	4);
test_getline("5a 5b 5c\n", 		"-", 	7);
test_getline("6\n", 			"-", 	10);
test_eof();

done_testing();
