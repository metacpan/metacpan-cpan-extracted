#!perl

# $Id: Lexer-comments.t,v 1.6 2010/11/21 16:48:35 Paulo Exp $

use strict;
use warnings;

use Test::More;
use File::Slurp;

require_ok 't/utils.pl';

our $pp;

#------------------------------------------------------------------------------
# pass two files to constructor, read in correct order
isa_ok $pp = Asm::Preproc->new('t/data/f01.asm', 't/data/f02.asm'), 'Asm::Preproc';
test_getline("hello\n",		't/data/f01.asm',	1);
test_getline("world\n",		't/data/f02.asm',	1);
test_eof();

#------------------------------------------------------------------------------
# one file to constructor, other included
isa_ok $pp = Asm::Preproc->new('t/data/f02.asm'), 'Asm::Preproc';
$pp->include('t/data/f01.asm');
test_getline("hello\n",		't/data/f01.asm',	1);
test_getline("world\n",		't/data/f02.asm',	1);
test_eof();

#------------------------------------------------------------------------------
# include as list
isa_ok $pp = Asm::Preproc->new, 'Asm::Preproc';
$pp->include_list('%include "t/data/f01.asm"', '%include "t/data/f02.asm"', );
test_getline("hello\n",		't/data/f01.asm',	1);
test_getline("world\n",		't/data/f02.asm',	1);
test_eof();

#------------------------------------------------------------------------------
# %include
isa_ok $pp = Asm::Preproc->new('t/data/f03.asm'), 'Asm::Preproc';
eval { $pp->getline };
is $@, "t/data/f03.asm(1) : error: %include expects a file name\n", "wrong syntax";

isa_ok $pp = Asm::Preproc->new('t/data/f04.asm'), 'Asm::Preproc';
test_getline("hello\n",		't/data/f01.asm',	1);
test_getline("world\n",		't/data/f02.asm',	1);
test_getline("hello\n",		't/data/f01.asm',	1);
test_getline("world\n",		't/data/f02.asm',	1);
test_eof();

#------------------------------------------------------------------------------
# path_search
isa_ok $pp = Asm::Preproc->new(), 'Asm::Preproc';
is_deeply [$pp->path], [], "empty path";
$pp->add_path('t/data');
is_deeply [$pp->path], ['t/data'], "one in path";
$pp->add_path('t/data/sub');
is_deeply [$pp->path], ['t/data', 't/data/sub'], "two in path";

is $pp->path_search('t/data/f01.asm'), 't/data/f01.asm', 
							"path search, file found before search";
is $pp->path_search('NO FILE'), 'NO FILE', 
							"path search, file not found";
like $pp->path_search('f01.asm'), qr{t[\\/]data[\\/]f01.asm}, 
							"path search, file found in first dir";
like $pp->path_search('f11.asm'), qr{t[\\/]data[\\/]sub[\\/]f11.asm}, 
							"path search, file found in second dir";

$pp->include('f06.asm');
test_getline("hello\n",		't/data/f01.asm',	1);
test_getline("world\n",		't/data/f02.asm',	1);
test_eof();

#------------------------------------------------------------------------------
# recursive include
isa_ok $pp = Asm::Preproc->new('t/data/f07.asm'), 'Asm::Preproc';
eval { $pp->getline };
is $@, "t/data/f08.asm(1) : error: %include loop\n",
			"%include loop";

done_testing();
