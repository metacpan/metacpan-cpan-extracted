#!perl

# $Id: AsmTable.t,v 1.4 2009/10/26 20:38:39 Paulo Custodio Exp $

use warnings;
use strict;

use Test::More;
use File::Slurp;

my $asm_file = "sjasmplus.asm";
my $bin_file = "sjasmplus.bin";
my $log_file = "sjasmplus.log";

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required unless RELEASE_TESTING" );
}

use_ok 'Asm::Z80::Table';

#------------------------------------------------------------------------------
# assemble with sjasmplus, compare assembly bytes
assemble("", "");			# empty input file

my @tests;
isa_ok my $iter = Asm::Z80::Table->iterator, 'CODE';
my($full_asm, $full_obj) = ("", "");
my $last;
while (my($tokens, $bytes) = $iter->()) {
	for (@$tokens) {
		if    ($_ eq 'N')		{ $_ = 1; }
		elsif ($_ eq 'DIS')		{ $_ = 2; }
		elsif ($_ eq 'NDIS')	{ $_ = 3; }
		elsif ($_ eq 'NN')		{ $_ = 4; }
		else 					{}
	}
	for (@$bytes) {
		if    ($_ eq 'N')		{ $_ = 1; }
		elsif ($_ eq 'DIS')		{ $_ = 2; }
		elsif ($_ eq 'DIS+1')	{ $_ = 3; }
		elsif ($_ eq 'NDIS')	{ $_ = -3 & 0xFF; }
		elsif ($_ eq 'NDIS+1')	{ $_ = (-3+1) & 0xFF; }
		elsif ($_ eq 'NNl')		{ $_ = 4; }
		elsif ($_ eq 'NNh')		{ $_ = 0; }
		elsif ($_ eq 'NNo')		{ $_ = 2; }
		else 					{}
	}
	
	my $asm = join(' ', @$tokens);
	my $obj = join('', map {chr} @$bytes);
	
	# jr/djnz have to be compiled separately; group others by instruction
	if ($asm =~ /jr|djnz/) {
		assemble($asm, $obj);
	}
	elsif ($last && substr($asm,0,2) ne $last) {
		# changed
		assemble($full_asm, $full_obj);
		($full_asm, $full_obj) = ("\t$asm\n", $obj);
	}
	else {
		# concatenate
		$full_asm .= "\t$asm\n";
		$full_obj .= $obj;
	}
	$last = substr($asm,0,2);
}
assemble($full_asm, $full_obj);

unlink $asm_file, $bin_file, $log_file;

done_testing();


#------------------------------------------------------------------------------
# assemble given code
sub assemble {
	my($asm, $obj) = @_;

	for ($asm) {
		# convert rst x --> rst x*8 (x in 1..7)
		s/(rst\s+)(\d+)/ $2 < 8 && $2 > 0 ? $1."8*".$2 : $1.$2 /giem;
		
		# convert 'jr po', etc to 'jp po'
		s/^jr(\s+(po|pe|p|m)\s*,)/jp$1/gim;		
	}
	
	unlink $bin_file, $log_file;
	write_file($asm_file, 
"
	macro stop
	db 0xDD, 0xDD, 0x00
	endm
	
	output $bin_file
	
	$asm
");

	my $cmd = "sjasmplus $asm_file > $log_file";
	my $ret = system $cmd;
	
	is $ret, 0, $cmd;
	is read_file($bin_file, binmode => ':raw'), $obj, $asm;
	like read_file($log_file), qr/^Errors: 0, warnings: 0,/mi, $log_file;
	
	die unless read_file($bin_file, binmode => ':raw') eq $obj;
}

#------------------------------------------------------------------------------
# assemble in blocks of code
