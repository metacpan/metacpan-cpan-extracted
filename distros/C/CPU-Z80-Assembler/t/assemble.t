#!perl

# $Id$

use strict;
use warnings;

use Test::More;
use File::Slurp;
use File::Spec;

use CPU::Z80::Assembler;

# script
my $infile =  't/data/test_z80.asm';
my $bmkfile = 't/data/test_z80.obj';
my $outfile = 't/test_z80.o';

my @input = read_file($infile);
my $output = read_file($bmkfile, binmode => ':raw');


	unlink $outfile;
ok 	-f $infile, "$infile exists";
ok 	-f $bmkfile, "$bmkfile exists";
ok	! -f $outfile, "$outfile does not exist";
is	system($^X, '-I'.File::Spec->catfile("blib", "lib"), 
			         File::Spec->catfile("blib", "script", "z80masm"),
			         $infile, $outfile), 0, 
	"z80masm $infile $outfile";
ok 	-f $outfile, "$outfile exists";
ok 	read_file($outfile, binmode => ':raw') eq $output, "$outfile eq $bmkfile";
	unlink $outfile;
ok	! -f $outfile, "$outfile deleted";	


# z80asm with list
ok z80asm(@input) eq $output, "z80asm(\@input)";

# z80asm with iterator
my $it = do { my @it = @input; sub {shift @it} };
ok z80asm($it) eq $output, "z80asm(sub {})";

# z80asm with file
ok z80asm("#include <$infile>") eq $output, "z80asm('#include <$infile>')";

# z80asm_file
ok z80asm_file($infile) eq $output, "z80asm_file(\$infile)";

done_testing;
