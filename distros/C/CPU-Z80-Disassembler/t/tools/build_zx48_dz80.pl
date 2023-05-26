#!perl

#------------------------------------------------------------------------------
# $Id$
# Generate a benchmark diassembly of zx48.rom by dZ80c.exe
# - converts hex dump to upper case
# - use $HHHH for hex constants
# - use decimal base in (ix+DIS)
# - do not decode invalid instructions ED.. and DD..
#------------------------------------------------------------------------------

use strict;
use warnings;

use File::Basename;
use File::Slurp;
use File::Copy;


my @delete_files;
END { @delete_files and unlink @delete_files };

my $DIS_CMD = 'dZ80c.exe ! -q -p="<<--" -y="-->>" -d="defb" ';


@ARGV==2 or die "Usage: ",basename($0)," INPUT_BINARY OUTPUT_DISASSEMBLY\n";
my($input, $output) = @ARGV;
my $output_temp = "$output~"; push @delete_files, $output_temp;

open(my $out, ">", $output_temp) or die "write $output: $!\n";

my $in = dis_stream($input);
while (my $line = $in->()) {
	print $out $line;
}
close $out;
move $output_temp, $output;

print "Created $output\n";


#------------------------------------------------------------------------------
# return a stream to return disassembled lines
sub dis_stream {
	my($file, $addr, $header, $length) = @_;
	
	my $index = qr/\b(?:ix|iy)\b/i;
	my $hex = qr/[0-9a-f]+/i;
	
	my @in;		# list of input handles
	push @in, dis_handle($file, $addr, $header, $length);
	
	return sub {
		for (;;) {
			return undef unless @in;
			my $in = $in[-1]; local $_ = <$in>; 
			unless (defined $_) { 
				close($in) or die;
				pop @in; 
				next; 
			}
			
			# convert dump to upper case, ignore lines without dump
			next unless s/^($hex)(\s+)($hex)/uc($1).$2.uc($3).' '/ige;
			
			# reduce space between opcode and args
			s/^($hex\s+$hex\s+\w+)[ \t]+/$1 /ig;
			s/ +$//;
			
			# convert hex constants to 0xHHHH
			s/<<--($hex)-->>/'0x'.uc($1)/ige;
						
			# convert ix/iy offsets to decimal
			# s/($index)\+0x($hex)/ hex($2) > 0 ? $1.'+'.hex($2) : $1 /ige;
			# s/($index)\-0x($hex)/ hex($2) > 0 ? $1.'-'.hex($2) : $1 /ige;
			s/($index)\+0x00/$1/ig;			# (ix+0) -> (ix)
			
			# convert DD00/FD00/ED00 created by a single byte file to defb
			s/^($hex\s+)(DD|FD)00(\s+)nop.*/$1$2$3  defb 0x$2/;
			s/^($hex\s+ED)00(\s+defb\s+0xED).*; Undocumented 8 T-State NOP.*/$1  $2/;
			
			# DD not followed by ix: dump a defb and continue on next address
			# FD not followed by iy: dump a defb and continue on next address
			if (/^($hex)\s+DD$hex/ && ! /ix/ ||
				/^($hex)\s+FD$hex/ && ! /iy/ ||
				/^($hex)\s+ED.*; Undocumented 8 T-State NOP/) {
				my $addr = hex($1);
				
				# discard current handle and create new ones
				1 while (<$in>); pop @in;
				push @in, dis_handle($file, $addr+1, $addr+1);
				push @in, dis_handle($file, $addr,   $addr,  1);
				next;
			}
			
			return $_;
		}
	};
}

sub dis_handle {
	my($file, $addr, $header, $length) = @_;
	
	$addr		||= 0;
	$header		||= 0;
	$length		||= (-s $file) - $header;
	
	# make temporary file for this segment
	my $temp_file = "$file.$addr.$header.$length.bin~"; 
	push @delete_files, $temp_file;
	
	my $data = read_file($file, binmode => ':raw');
	write_file($temp_file, {binmode => ':raw' },
			   substr($data, $header, $length));	
	
	open(my $in, $DIS_CMD."-m=$addr $temp_file |") 
		or die "dZ80c.exe: $!\n";
	return $in;
}

	
