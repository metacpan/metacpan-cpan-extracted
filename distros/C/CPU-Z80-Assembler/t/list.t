#!perl

# $Id$

use strict;
use warnings;

use CPU::Z80::Assembler;
use Test::More tests => 12;
use File::Slurp;
use File::Spec;

my $infile =  		't/data/list.asm';
my $bmkoutfile = 	't/data/list.hex';
my $bmklstfile = 	't/data/list.lst';
my $outfile = 		't/list.o';
my $lstfile = 		't/list.lst';

	unlink $outfile, $lstfile;
	for ($infile, $bmkoutfile, $bmklstfile) {
		ok	-f $_, "$_ exists";
	}
	for ($outfile, $lstfile) {
		ok	! -f $_, "$_ should not exist";
	}
	
is	system($^X." -I".File::Spec->catfile("blib", "lib")." ". 
			         File::Spec->catfile("blib", "script", "z80masm")." ".
			         $infile." ".
			         $outfile." > ".$lstfile), 0, 
	"bin/z80masm $infile $outfile > $lstfile";

	for ($outfile, $lstfile) {
		ok	-f $_, "$_ exists";
	}

	# insert version number in lst file as variable
	# handle \r 
	my $lst = read_file($lstfile);
	$lst =~ s/\A([^\n]*v)$CPU::Z80::Assembler::VERSION/$1\$CPU::Z80::Assembler::VERSION/;
	$lst =~ s/\r//g;
	write_file($lstfile, $lst);
	
	my $bmklst = read_file($bmklstfile);
	$bmklst =~ s/\r//g;
	
	my $lst_ok = $lst eq $bmklst;
ok 	$lst_ok, "files equal : $bmklstfile $lstfile";

	my $out_hex = join(' ', map { sprintf("%02X", ord($_)) } split(//, 
												read_file($outfile, binmode => ':raw')));
	my $bmk_hex = read_file($bmkoutfile); 
	for ($bmk_hex) {
		s/\s+/ /g;
		s/^\s+//;
		s/\s+$//g;
	}

	my $obj_ok = $out_hex eq $bmk_hex;
is 	$out_hex, $bmk_hex, "$outfile OK";

	unlink $outfile, $lstfile if ($lst_ok && $obj_ok);
	for ($outfile, $lstfile) {
		ok	! -f $_, "$_ should not exist";
	}

