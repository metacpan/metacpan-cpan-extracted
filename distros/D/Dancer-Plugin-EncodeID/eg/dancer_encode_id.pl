#!/usr/bin/env perl
use strict;
use warnings;
use Dancer ':script';
use Dancer::Plugin::EncodeID;
use Getopt::Long;

our $VERSION=0.2;

sub show_usage();
sub parse_commandline();

my $secret = "Super-Secret";
my $input_id;
my $prefix;
my $verbose;
my $decode; ## if defined, decode a hashed-ID instead of encoding it.

##
## Program Start
##

show_usage() unless @ARGV;
parse_commandline();

setting plugins => { EncodeID => { secret => $secret } };

my $result = ($decode)?
		decode_id($input_id, $prefix):
		encode_id($input_id, $prefix);

my $func_name = ($decode)?"decode_id":"encode_id";
my $prefix_param = ($prefix)?",'$prefix'":"";

print "$func_name($input_id$prefix_param) = " if $verbose;

print $result, "\n";

##
## Program End
##

sub parse_commandline()
{
	my $rc = GetOptions(
			"encode|e" => sub { },
			"decode|d" => \$decode,
			"verbose|v" => \$verbose,
			"help|h"   => \&show_usage,
			"secret|s=s" => \$secret,
	);
	die "Invalid command line parameters.\n" unless $rc;

	die "Error: missing ID parameter. See --help for details.\n" unless @ARGV;

	$input_id = shift @ARGV;

	die "Error: invalid ID ($input_id) - must be numeric value.\n"
		if !$decode && $input_id !~ /^\d+$/;

	die "Error: invalid ID ($input_id) - must be hex-decimal string.\n"
		if $decode && $input_id !~ /^[A-Fa-f0-9]+$/;

	## Next optional parameter is the PREFIX
	if (scalar(@ARGV)>0) {
		$prefix = shift @ARGV;
		die "Error: invalid PREFIX ($prefix) - must be a single letter/digit.\n"
			unless $prefix =~ /^[A-Za-z0-9]$/;
	}

	die "Error: too many parameters on command line. See --help for usage information.\n"
		unless scalar(@ARGV)==0;
}

sub show_usage()
{
	print<<EOF;
Dancer-Encode-ID - Command-line interface to Dancer::Plugin::EncodeID
Version $VERSION
Copyright 2011 (C) - A. Gordon ( gordon\@cshl.edu )

Usage:
   dancer_encode_id.pl [OPTIONS] ID [PREFIX]

   ID = The numeric ID to encode,
        or
        The hashed/encoded ID to decode (if using --decode)

  [PREFIX] - optional one-letter prefix used to encode/decode the ID.

Options:
   -d
   --decode   -   Decode a prefiously encoded ID.
                  (Default is encoding).

   -e
   --encode   -   Encode the ID (the default).

   -v
   --verbose  -   Show the parameters (ID,PREFIX).

   -h
   --help     -   This helpful help screen.

   -s TEXT
   --secret TEXT - Use this text as secret key.
                   (default = '$secret').


Example:
   ## Simple encoding with the default key
   \$ dancer_encode_id.pl 102
   c485599b7e775637

   \$ dancer_encode_id.pl 103
   778437dd3169a8c6

   \$ dancer_encode_id.pl 104
   80f52e2e076147ae

   ## Use a Prefix to affect the hash, making sure same numeric values
   ## Give different hashes.
   \$ dancer_encode_id.pl 102 A
   2586ebc55744384c

   \$ dancer_encode_id.pl 102 G
   3344c214de62e338

   \$ dancer_encode_id.pl 102 x
   66689a236caef1e8

   ## Use a different key
   \$ dancer_encode_id.pl --secret "HelloWorld" 102 x
   731ae497115a426b

   ## Decoding
   \$ dancer_encode_id.pl --decode c485599b7e775637
   102

   ## Decoding with a prefix
   \$ dancer_encode_id.pl --decode 66689a236caef1e8 x
   102

   ##If you omit the prefix (but encoded with it), it will simply appear in the ID
   \$ dancer_encode_id.pl --decode 66689a236caef1e8
   x102

   ##If you encode with a prefix, it will be used to check the ID is valid
   \$ dancer_encode_id.pl --decode 66689a236caef1e8
   x102

   \$ dancer_encode_id.pl --decode 66689a236caef1e8 R
   Invalid Hash-ID value (66689a236caef1e8) - bad prefix

   ## Just checking...
   \$ dancer_encode_id.pl --decode \$(dancer_encode_id.pl 105)
   105

   ## Decoding with a wrong key will not fail, but produce binary junk.
   ## So ALWAYS check (with regex) the validity of your ID,
   ## or simply use a prefix
   \$ dancer_encode_id.pl --secret "HelloWorld" 102
   1a285a3e3597fa8b

   # Decode with wrong key, without a prefix
   \$ dancer_encode_id.pl --decode --secret "GoodbyeWorld" 1a285a3e3597fa8b
   [Binary junk]

EOF
}
