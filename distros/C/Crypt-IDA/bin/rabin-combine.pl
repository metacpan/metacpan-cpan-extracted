#!/usr/bin/perl -w
#
# Simple command line-handling wrapper to create IDA share files

use strict;
use warnings;
use Getopt::Long;
use Crypt::IDA::ShareFile ":all";

# Help option
my $need_help=0;

# Required parameters
my $infiles=undef;
my $outfile=undef;

# Optional parameters which have default values in sf_split
my $bufsize=4096;

Getopt::Long::Configure ("bundling");
my $r=GetOptions ( "h|help"     => \$need_help,
		   "o|outfile=s" => \$outfile,
		   "B|bufsize=i" => \$bufsize,
		 );
$infiles=[@ARGV];

if ($need_help or scalar(@$infiles) == 0) {
  print <<HELP;
$0 : combine files created with rabin-split.pl

Usage:

 $0 [options] infile1 infile2 ...

Options:

 -h       --help                  View this help message and quit
 -o file  --outfile file        * Specify output file name
 -B int   --bufsize int           Set I/O buffer size

Options marked with * must be supplied.

This script can only combine one chunk of the output file at a time.
To combine all chunks re-run the script once for each chunk specifying
the same output file name, but different input share files.

HELP
  exit 0;
}

sf_combine(infiles => $infiles, outfile => $outfile );

