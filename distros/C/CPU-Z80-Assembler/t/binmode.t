#!perl

# $Id$

use strict;
use warnings;

use Test::More tests => 7;
use File::Slurp;
use File::Spec;

my $infile =  't/04-binmode.asm';
my $outfile = 't/04-binmode.o';

	write_file($infile, "LD A,0x0D\nLD B,0x0A\n");
	unlink $outfile;
ok 	-f $infile, "$infile exists";
ok	! -f $outfile, "$outfile does not exist";
is	system($^X, '-I'.File::Spec->catfile("blib", "lib"), 
			         File::Spec->catfile("blib", "script", "z80masm"),
			         $infile, $outfile), 0, 
	"z80masm $infile $outfile";
ok 	-f $outfile, "$outfile exists";
is 	read_file($outfile, binmode => ':raw'), "\x3E\x0D\x06\x0A", "$outfile OK";
	unlink $infile, $outfile;
ok	! -f $infile, "$infile deleted";
ok	! -f $outfile, "$outfile deleted";	
