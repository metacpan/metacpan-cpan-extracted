#!/bin/perl
#
# Perl.pm - Algorithm::Hamming::Perl library. Implements 8,4 bit Hamming ECC.
#
#	This code will be unusual to read - instead of finding the Hamming
# algorithm you will see hash after hash after hash. These are used to 
# improve the speed of the library, and act as a cache of preprocessed 
# results. An optional subrourine may be run: 
#	Algorithm::Hamming::Perl::hamming_faster()
# which uses a bigger cache for faster encoding/decoding (but more memory 
# and slower startups).
#
# 18-Oct-2003	Brendan Gregg	Created this.


package Algorithm::Hamming::Perl;

use 5.006;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(hamming unhamming unhamming_err);

our $VERSION = '0.05';


my %Hamming8raw;	# This hash is used during initialisation only. It
			# contains binary text keys and binary text values
			# as [data] -> [Hamming code] lookups, 
			# eg "00001010" => "000001010010"

my %Hamming8semi;	# This hash is semi-processed, and is used in "slow"
			# encoding mode. It contains byte keys and binary
			# text values as [data] -> [Hamming code] lookups,
			# eg "A" => "010010000100"

my %Hamming8by2;	# This hash is fully-processed and provides speed at
			# the cost of memory. It contains 2 byte keys and
			# 3 byte values as [data] -> [Hamming code] lookups,
			# eg "AA" => "HD "	   # (whatever the code is!)
			# By using this hash, the program can read an
			# input stream 2 bytes at a time, writing an output
			# stream 3 bytes at a time - no messing aroung 
			# with half bytes or byte boundaries.

my %Hamming8rev;	# This hash is semi-processed, and is used for 
			# decoding Hamming code to data. It contains 
			# binary text values for keys and bytes for values
			# as [Hamming code] -> [data] lookups,
			# eg "010010000100" => "A"

my %Hamming8by2rev;	# This hash is fully-processed and provides speed at
			# the cost of memory. It contains 3 byte keys and
			# 2 byte values as [Hamming code] -> [data] lookups,
			# eg "HD " => "AA"	   # (whatever the code is!)
			# By using this hash, the program can read an
			# input stream 3 bytes at a time, writing an output
			# stream 2 bytes at a time - no messing aroung 
			# with half bytes or byte boundaries.

my ($x,$y,$key,$char,$char1,$char2,$chars,$char_out,$ham_text,$number);

#
#  Hamming8raw is NOT the lookup table used! :)
#  (that would be dreadfully inefficient). 
#  This hash is processed into a bytes -> bytes lookup.
#
%Hamming8raw = ("00000000" => "000000000000",
		"00000001" => "000000000111",
		"00000010" => "000000011001",
		"00000011" => "000000011110",
		"00000100" => "000000101010",
		"00000101" => "000000101101",
		"00000110" => "000000110011",
		"00000111" => "000000110100",
		"00001000" => "000001001011",
		"00001001" => "000001001100",
		"00001010" => "000001010010",
		"00001011" => "000001010101",
		"00001100" => "000001100001",
		"00001101" => "000001100110",
		"00001110" => "000001111000",
		"00001111" => "000001111111",
		"00010000" => "000110000001",
		"00010001" => "000110000110",
		"00010010" => "000110011000",
		"00010011" => "000110011111",
		"00010100" => "000110101011",
		"00010101" => "000110101100",
		"00010110" => "000110110010",
		"00010111" => "000110110101",
		"00011000" => "000111001010",
		"00011001" => "000111001101",
		"00011010" => "000111010011",
		"00011011" => "000111010100",
		"00011100" => "000111100000",
		"00011101" => "000111100111",
		"00011110" => "000111111001",
		"00011111" => "000111111110",
		"00100000" => "001010000010",
		"00100001" => "001010000101",
		"00100010" => "001010011011",
		"00100011" => "001010011100",
		"00100100" => "001010101000",
		"00100101" => "001010101111",
		"00100110" => "001010110001",
		"00100111" => "001010110110",
		"00101000" => "001011001001",
		"00101001" => "001011001110",
		"00101010" => "001011010000",
		"00101011" => "001011010111",
		"00101100" => "001011100011",
		"00101101" => "001011100100",
		"00101110" => "001011111010",
		"00101111" => "001011111101",
		"00110000" => "001100000011",
		"00110001" => "001100000100",
		"00110010" => "001100011010",
		"00110011" => "001100011101",
		"00110100" => "001100101001",
		"00110101" => "001100101110",
		"00110110" => "001100110000",
		"00110111" => "001100110111",
		"00111000" => "001101001000",
		"00111001" => "001101001111",
		"00111010" => "001101010001",
		"00111011" => "001101010110",
		"00111100" => "001101100010",
		"00111101" => "001101100101",
		"00111110" => "001101111011",
		"00111111" => "001101111100",
		"01000000" => "010010000011",
		"01000001" => "010010000100",
		"01000010" => "010010011010",
		"01000011" => "010010011101",
		"01000100" => "010010101001",
		"01000101" => "010010101110",
		"01000110" => "010010110000",
		"01000111" => "010010110111",
		"01001000" => "010011001000",
		"01001001" => "010011001111",
		"01001010" => "010011010001",
		"01001011" => "010011010110",
		"01001100" => "010011100010",
		"01001101" => "010011100101",
		"01001110" => "010011111011",
		"01001111" => "010011111100",
		"01010000" => "010100000010",
		"01010001" => "010100000101",
		"01010010" => "010100011011",
		"01010011" => "010100011100",
		"01010100" => "010100101000",
		"01010101" => "010100101111",
		"01010110" => "010100110001",
		"01010111" => "010100110110",
		"01011000" => "010101001001",
		"01011001" => "010101001110",
		"01011010" => "010101010000",
		"01011011" => "010101010111",
		"01011100" => "010101100011",
		"01011101" => "010101100100",
		"01011110" => "010101111010",
		"01011111" => "010101111101",
		"01100000" => "011000000001",
		"01100001" => "011000000110",
		"01100010" => "011000011000",
		"01100011" => "011000011111",
		"01100100" => "011000101011",
		"01100101" => "011000101100",
		"01100110" => "011000110010",
		"01100111" => "011000110101",
		"01101000" => "011001001010",
		"01101001" => "011001001101",
		"01101010" => "011001010011",
		"01101011" => "011001010100",
		"01101100" => "011001100000",
		"01101101" => "011001100111",
		"01101110" => "011001111001",
		"01101111" => "011001111110",
		"01110000" => "011110000000",
		"01110001" => "011110000111",
		"01110010" => "011110011001",
		"01110011" => "011110011110",
		"01110100" => "011110101010",
		"01110101" => "011110101101",
		"01110110" => "011110110011",
		"01110111" => "011110110100",
		"01111000" => "011111001011",
		"01111001" => "011111001100",
		"01111010" => "011111010010",
		"01111011" => "011111010101",
		"01111100" => "011111100001",
		"01111101" => "011111100110",
		"01111110" => "011111111000",
		"01111111" => "011111111111",
		"10000000" => "100010001000",
		"10000001" => "100010001111",
		"10000010" => "100010010001",
		"10000011" => "100010010110",
		"10000100" => "100010100010",
		"10000101" => "100010100101",
		"10000110" => "100010111011",
		"10000111" => "100010111100",
		"10001000" => "100011000011",
		"10001001" => "100011000100",
		"10001010" => "100011011010",
		"10001011" => "100011011101",
		"10001100" => "100011101001",
		"10001101" => "100011101110",
		"10001110" => "100011110000",
		"10001111" => "100011110111",
		"10010000" => "100100001001",
		"10010001" => "100100001110",
		"10010010" => "100100010000",
		"10010011" => "100100010111",
		"10010100" => "100100100011",
		"10010101" => "100100100100",
		"10010110" => "100100111010",
		"10010111" => "100100111101",
		"10011000" => "100101000010",
		"10011001" => "100101000101",
		"10011010" => "100101011011",
		"10011011" => "100101011100",
		"10011100" => "100101101000",
		"10011101" => "100101101111",
		"10011110" => "100101110001",
		"10011111" => "100101110110",
		"10100000" => "101000001010",
		"10100001" => "101000001101",
		"10100010" => "101000010011",
		"10100011" => "101000010100",
		"10100100" => "101000100000",
		"10100101" => "101000100111",
		"10100110" => "101000111001",
		"10100111" => "101000111110",
		"10101000" => "101001000001",
		"10101001" => "101001000110",
		"10101010" => "101001011000",
		"10101011" => "101001011111",
		"10101100" => "101001101011",
		"10101101" => "101001101100",
		"10101110" => "101001110010",
		"10101111" => "101001110101",
		"10110000" => "101110001011",
		"10110001" => "101110001100",
		"10110010" => "101110010010",
		"10110011" => "101110010101",
		"10110100" => "101110100001",
		"10110101" => "101110100110",
		"10110110" => "101110111000",
		"10110111" => "101110111111",
		"10111000" => "101111000000",
		"10111001" => "101111000111",
		"10111010" => "101111011001",
		"10111011" => "101111011110",
		"10111100" => "101111101010",
		"10111101" => "101111101101",
		"10111110" => "101111110011",
		"10111111" => "101111110100",
		"11000000" => "110000001011",
		"11000001" => "110000001100",
		"11000010" => "110000010010",
		"11000011" => "110000010101",
		"11000100" => "110000100001",
		"11000101" => "110000100110",
		"11000110" => "110000111000",
		"11000111" => "110000111111",
		"11001000" => "110001000000",
		"11001001" => "110001000111",
		"11001010" => "110001011001",
		"11001011" => "110001011110",
		"11001100" => "110001101010",
		"11001101" => "110001101101",
		"11001110" => "110001110011",
		"11001111" => "110001110100",
		"11010000" => "110110001010",
		"11010001" => "110110001101",
		"11010010" => "110110010011",
		"11010011" => "110110010100",
		"11010100" => "110110100000",
		"11010101" => "110110100111",
		"11010110" => "110110111001",
		"11010111" => "110110111110",
		"11011000" => "110111000001",
		"11011001" => "110111000110",
		"11011010" => "110111011000",
		"11011011" => "110111011111",
		"11011100" => "110111101011",
		"11011101" => "110111101100",
		"11011110" => "110111110010",
		"11011111" => "110111110101",
		"11100000" => "111010001001",
		"11100001" => "111010001110",
		"11100010" => "111010010000",
		"11100011" => "111010010111",
		"11100100" => "111010100011",
		"11100101" => "111010100100",
		"11100110" => "111010111010",
		"11100111" => "111010111101",
		"11101000" => "111011000010",
		"11101001" => "111011000101",
		"11101010" => "111011011011",
		"11101011" => "111011011100",
		"11101100" => "111011101000",
		"11101101" => "111011101111",
		"11101110" => "111011110001",
		"11101111" => "111011110110",
		"11110000" => "111100001000",
		"11110001" => "111100001111",
		"11110010" => "111100010001",
		"11110011" => "111100010110",
		"11110100" => "111100100010",
		"11110101" => "111100100101",
		"11110110" => "111100111011",
		"11110111" => "111100111100",
		"11111000" => "111101000011",
		"11111001" => "111101000100",
		"11111010" => "111101011010",
		"11111011" => "111101011101",
		"11111100" => "111101101001",
		"11111101" => "111101101110",
		"11111110" => "111101110000",
		"11111111" => "111101110111");


#
#  Build Hamming lookup tables
#
foreach $key (sort { $a <=> $b } keys %Hamming8raw) {
	$char = pack("B*",$key);
	$Hamming8semi{$char} = $Hamming8raw{$key};
}
%Hamming8rev = reverse(%Hamming8semi);	


# hamming_faster - this subroutine builds two large hashes of,
#		%Hamming8by2	  2 byte data -> 3 byte Hamming code
#		%Hamming8by2rev	  3 byte Hamming code -> 2 byte data
#	for faster encodings and decodings. Running this subroutine is 
#	optional. If it is used then conversions are faster, however more 
#	memory is used to store the hashes, and a couple of seconds is added 
#	to the startup time. If it is not used, conversions are slower -
#	taking up to 5 times the usual time. A good measure is the data you
#	with to encode - more than 1 Mb would benifit from this subroutine.
#
sub hamming_faster {

	#
	#  Step through 0,0 to 255,255 to build a hash that can convert
	#  any 2 byte combinations.
	#
	for ($x=0; $x<256; $x++) {
		for ($y=0; $y<256; $y++) {

			### Convert numbers into 2 bytes
			$char1 = chr($x);
			$char2 = chr($y);
			$chars = $char1 . $char2;

			### Generating 24 bit Hamming code
			$ham_text = $Hamming8semi{$char1} . 
			 $Hamming8semi{$char2};
			
			### Make 3 byte Hamming code
			$char_out = pack("B*",$ham_text);

			### Add to hash
			$Hamming8by2{$chars} = $char_out;
		}
	}
	%Hamming8by2rev = reverse(%Hamming8by2);
}
	

# hamming - this turns data into hamming code. This has been written 
#  	with memory and CPU efficiency in mind (without resorting to C).
#
sub hamming {
	my $data = shift;	# input data
	my $pos;		# counter to step through data string
	my $char_in1;		# first input byte
	my $char_in2;		# second input byte
	my $chars_in;		# both input bytes
	my $ham_text;		# hamming code in binary text "0101.."
	my $char_out;		# hamming code as bytes
	my $output = "";	# full output hamming code as bytes

	my $length = length($data);
	
	#
	#  Step through the $data 2 bytes at a time, generating a
	#  Hamming encoded $output.
	#
	for ($pos = 0; $pos < ($length-1); $pos+=2) {

		$chars_in = substr($data,$pos,2);
		if (defined $Hamming8by2{$chars_in}) {
			#
			#  Fast method
			#
			$output .= $Hamming8by2{$chars_in};
		} else {
			#
			#  Slow method
			#

			### Get both chars
			$char_in1 = substr($data,$pos,1);
			$char_in2 = substr($data,$pos+1,1);

			### Make a 24 bit hamming binary number
			$ham_text = $Hamming8semi{$char_in1} . 
			 $Hamming8semi{$char_in2};

			### Turn this number into 3 bytes
			$char_out = pack("B*",$ham_text);

			### Add to output
			$output .= $char_out;
		}
	}

	#
	#  A leftover byte (if present) is padded with 0's.
	#
	if ($length == ($pos + 1)) {

		### Get the last character
		$char_in1 = substr($data,$pos,1);

		### Generate padded hamming text
		$ham_text = $Hamming8semi{$char_in1} . "0000";
	
		### Turn into 2 bytes
		$char_out = pack("B*",$ham_text);

		### Add to output
		$output .= $char_out;
	}
	
	return $output;
}


# unhamming_err - this turns hamming code into data. This has been written 
# 	with memory and CPU efficiencu in mind (without resorting to C).
#
sub unhamming_err {
	my $data = shift;	# input data
	my $pos;		# counter to step through data string
	my $err;		# corrected bit error
	my $chars_in;		# input bytes
	my $ham_text;		# hamming code in binary text "0101..", 2 bytes
	my $ham_text1;		# hamming code for first byte
	my $ham_text2;		# hamming code for second byte
	my $char_out1;		# output data byte 1
	my $char_out2;		# output data byte 2
	my $output = "";	# full output data as bytes
	my $err_all = 0;	# count of corrected bit errors

	my $length = length($data);
	
	# 
	#  Step through the $data 3 bytes at a time, decoding it back into
	#  the $output data.
	#
	for ($pos = 0; $pos < ($length-2); $pos+=3) {

		### Fetch 3 bytes
		$chars_in = substr($data,$pos,3);

		if (defined $Hamming8by2rev{$chars_in}) {
			#
			#  Fast method
			#
			$output .= $Hamming8by2rev{$chars_in};
		} else {
			#
			#  Slow method
			#

			### Fetch the 2 Hamming codes
			$ham_text = unpack("B*",$chars_in);
			$ham_text1 = substr($ham_text,0,12);
			$ham_text2 = substr($ham_text,12);

			### Convert each code into the original byte
			($char_out1,$err) = unhamchar($ham_text1);
			$err_all += $err;
			($char_out2,$err) = unhamchar($ham_text2);
			$err_all += $err;

			### Add bytes to output
			$output .= $char_out1 . $char_out2;
		}
	}

	#
	#  Decode leftover bytes (if present).
	#
	if ($length == ($pos + 2)) {
		### Fetch the 2 leftover bytes
		$chars_in = substr($data,$pos,2);

		### Fetch the Hamming code
		$ham_text = unpack("B*",$chars_in);
		$ham_text1 = substr($ham_text,0,12);
	
		### Convert the code to the original byte
		($char_out1,$err) = unhamchar($ham_text1);
		$err_all += $err;

		### Add byte to output
		$output .= $char_out1;
	}
	
	return ($output,$err_all);
}


# unhamming - this is a wrapper around unhamming_err that just returns 
#		the data.
#
sub unhamming {
	my $data = shift;
	my ($output,$err);

	($output,$err) = unhamming_err($data);
	return $output;
}


# unhamchar - this takes a hamming code as binary text "0101..." and returns
#		both the char and number (0 or 1) to represent if correction
#		occured.
#
sub unhamchar {
	my $text = shift;
	my $pos = 0;				# counter
	my $err = 0;				# error bit position
	my ($bit);

	### If okay, return now
	if (defined $Hamming8rev{$text}) {
		return ($Hamming8rev{$text},0);
	}

	### Find error bit
	my $copy = $text;
	while ($copy ne "") {
		$pos++;
		$bit = chop($copy);
		if ($bit eq "1") {
			$err = $err ^ $pos;
		}
	}

	### Correct error bit
	$copy = $text;
	if ($err <= 12) {
		$bit = substr($copy,-$err,1);
		if ($bit eq "0") { $bit = "1"; }
		 else { $bit = "0"; }
		substr($copy,-$err,1) = $bit;
	}

        ### If okay now, return
        if (defined $Hamming8rev{$copy}) {
                return ($Hamming8rev{$copy},1);
        }

	### We shouldn't get here
	return ("\0",1);
}



1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Algorithm::Hamming::Perl - Perl implementation of ECC Hamming encoding, 
for single bit auto error correction.

=head1 SYNOPSIS

use Algorithm::Hamming::Perl  qw(hamming unhamming);

$code = hamming($data);              # Encode $data

$data = unhamming($code);            # Decode and fix errors
($data,$errors) = unhamming($code);  #  + return error count


=head1 DESCRIPTION

This is an Error Correction Code module, implementing Hamming encoding
(8 bits data, 4 bits Hamming - ie increases data size by 50%). Data can
be encoded so that single bit errors within a byte are auto-corrected.

This may be useful as a precaution before storing or sending data where
single bit errors are expected.

Hamming encoding was invented by Richard Hamming, Bell Labs, during 1948.

=head1 EXPORT SUBROUTINES

=over 4

=item hamming (SCALAR)

Returns the Hamming code from the provided input data.

=item unhamming (SCALAR)

Returns the original data from the provided Hamming code. Single bit errors
are auto corrected.

=item unhamming_err (SCALAR)

Returns the original data from the provided Hamming code, and a number counting
the number of bytes that were corrected. Single bit errors are auto corrected. 

=back

=head1 OTHER SUBROUTINES

=over 4

=item Algorithm::Hamming::Perl::hamming_faster ()

This is an optional subroutine that will speed Hamming encoding if it is
run once at the start of the program. It does this by using a larger (hash)
cache of preprocessed results. The disadvantage is that it uses more memory,
and can add several seconds to invocation time. Only use this if you are
encoding more than 1 Mb of data.

=back

=head1 INSTALLATION

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES

ExtUtils::MakeMaker

=head1 EXAMPLES

See the example perl programs provided with this module "example*". 
An encoding and decoding example,

   use Algorithm::Hamming::Perl  qw(hamming unhamming);
   
   $data = "Hello";
   $hamcode = hamming($data);

   $original = unhamming($hamcode);

=head1 LIMITATIONS

This is Perl only and can be slow. The Hamming encoding used can only
repair a single bit error within a byte - ie if two bits are damaged within
the one byte then this encoding cannot auto correct the error.

=head1 BUGS

Try not to join Hamming encoded strings together - this may give results
that look like a bug. If an odd number of input byes is encoded, the output
code is short half a byte - and so is padded with '0' bits. Joining these 
with a string concatenation will contain the padding bits that will confuse 
decoding. 

The above problem can occur when inputing and outputing certain lengths
to filehandles. To be safe, my example code uses a buffer of 3072 bytes - 
a safe size to use with filehandles.

=head1 COPYRIGHT

Copyright (c) 2003 Brendan Gregg. All rights reserved.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=head1 AUTHOR

Brendan Gregg <brendan.gregg@tpg.com.au>
[Sydney, Australia]

=cut
