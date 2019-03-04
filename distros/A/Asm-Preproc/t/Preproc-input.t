#!perl

# $Id: Lexer-comments.t,v 1.6 2010/11/21 16:48:35 Paulo Exp $

use strict;
use warnings;

use Test::More;
use File::Slurp;

require_ok 't/utils.pl';

our $pp;

my @input = map {"$_\n"} 1..4;
my $input = join '', @input;

#------------------------------------------------------------------------------
# test input from file
my $file = "$0.tmp"; $file =~ s/\\/\//g;

# no file
unlink($file);
ok ! -f unlink($file), "no $file";
eval { Asm::Preproc->new($file) };
is $@, "error: unable to open input file '$file'\n";

# empty file
write_file($file);		
isa_ok $pp = Asm::Preproc->new, 'Asm::Preproc';
$pp->include($file);
test_eof();
ok unlink($file), "unlink $file";

# file with data
write_file($file, $input);
isa_ok $pp = Asm::Preproc->new, 'Asm::Preproc';
$pp->include($file);
test_getline("1\n", 	$file, 	1);
test_getline("2\n", 	$file, 	2);
test_getline("3\n", 	$file, 	3);
test_getline("4\n", 	$file, 	4);
test_eof();
ok unlink($file), "unlink $file";

# file with data, pass on constructor
write_file($file, $input);
isa_ok $pp = Asm::Preproc->new($file), 'Asm::Preproc';
test_getline("1\n", 	$file, 	1);
test_getline("2\n", 	$file, 	2);
test_getline("3\n", 	$file, 	3);
test_getline("4\n", 	$file, 	4);
test_eof();
ok unlink($file), "unlink $file";

#------------------------------------------------------------------------------
# test input from list
isa_ok $pp = Asm::Preproc->new, 'Asm::Preproc';
test_eof();

isa_ok $pp = Asm::Preproc->new, 'Asm::Preproc';
$pp->include_list(undef, "");
test_eof();

isa_ok $pp = Asm::Preproc->new, 'Asm::Preproc';
$pp->include_list(1,2,"3\r\r\n4\r");
test_getline("1\n", 	"-", 	1);
test_getline("2\n", 	"-", 	2);
test_getline("3\n", 	"-", 	3);
test_getline("4\n", 	"-", 	4);
test_eof();

isa_ok $pp = Asm::Preproc->new, 'Asm::Preproc';
$pp->include_list(undef, "", @input);
test_getline("1\n", 	"-", 	1);
test_getline("2\n", 	"-", 	2);
test_getline("3\n", 	"-", 	3);
test_getline("4\n", 	"-", 	4);
test_eof();

#------------------------------------------------------------------------------
# test input from one big string
isa_ok $pp = Asm::Preproc->new, 'Asm::Preproc';
$pp->include_list(undef, "", $input);
test_getline("1\n", 	"-", 	1);
test_getline("2\n", 	"-", 	2);
test_getline("3\n", 	"-", 	3);
test_getline("4\n", 	"-", 	4);
test_eof();


#------------------------------------------------------------------------------
# test input from iterators
my @iter;
for (1..2) {
	my @input_copy = @input;
	push @iter, sub { shift @input_copy };
}
isa_ok $pp = Asm::Preproc->new, 'Asm::Preproc';
$pp->include_list(undef, "", @iter);
test_getline("1\n", 	"-", 	1);
test_getline("2\n", 	"-", 	2);
test_getline("3\n", 	"-", 	3);
test_getline("4\n", 	"-", 	4);
test_getline("1\n", 	"-", 	5);
test_getline("2\n", 	"-", 	6);
test_getline("3\n", 	"-", 	7);
test_getline("4\n", 	"-", 	8);
test_eof();

done_testing();
