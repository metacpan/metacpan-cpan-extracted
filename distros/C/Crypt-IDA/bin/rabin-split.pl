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
my $infile=undef;
my $quorum=undef;
my $shares=undef;

# Optional parameters which have default values in sf_split
my $filespec=undef;
my $width=1;
my $rand='/dev/urandom';
my $bufsize=4096;

# Optional parameters which don't have defaults
my $sharelist=undef;
my $chunklist=undef;
my $n_chunks=undef;
my $in_chunk_size = undef;
my $out_chunk_size = undef;
my $out_file_size = undef;

Getopt::Long::Configure ("bundling");
my $r=GetOptions ( "h|help"     => \$need_help,
		   "i|infile=s" => \$infile,
		   "k|t|quorum=i" => \$quorum,
		   "n|shares=i" => \$shares,
		   "P|filespec=s" => \$filespec,
		   "w|width|s|security=i" => \$width,
		   "R|rand=s" => \$rand,
		   "B|bufsize=i" => \$bufsize,
		   "S|sharelist=s" => \$sharelist,
		   "C|chunklist=s" => \$chunklist,
		   "N|n_chunks=i" => \$n_chunks,
		   "I|in_chunk_size=i" => \$in_chunk_size,
		   "O|out_chunk_size=i" => \$out_chunk_size,
		   "F|out_file_size=i" => \$out_file_size
		 );

$infile=shift unless defined $infile;

if ($need_help or !defined($quorum) or !defined($shares) or 
    !defined($infile)) {
  print <<HELP;
$0 : split file using Rabin's Information Dispersal Algorithm

Usage:

 $0 [options] infile

Options:

 -h       --help                  View this help message and quit
 -i file  --infile file           Specify input file (alternative method)
 -k int   --quorum int, -t int  * Set quorum ("threshold") value to int
 -n int   --shares int          * Set number of shares to int
 -w int   --width int,
          --security int        * Set field width to 1, 2 or 4 bytes
 -P patt  --filespec patt         Set sharefile naming pattern
 -R str   --rand str              Set random number source ("rand" or filename)
 -B int   --bufsize int           Set I/O buffer size
 -S list  --sharefile list        Set list of shares to be created
 -C list  --chunklist list        Set list of chunks to be created
 -N int   --n_chunks int          Chunk file calculation by number of chunks
 -I int   --in_chunk_size int     Chunk file calculation by input chunk size
 -O int   --out_chunk_size int    Chunk file calculation by output chunk size
 -F int   --out_file_size int     Chunk file calculation by output file size

Options marked with * must be supplied.

Specifying output sharefile name patterns ("patt"):

 \%f     original (input) filename
 \%c     chunk number (0 .. chunks - 1)
 \%s     share number (0 .. shares - 1)

Specifying share or chunk lists ("list"), eg:

 1,4-6,8

Creates chunks/shares 1, 4, 5, 6, and 8.

HELP
  exit 0;
}

sf_split( filename => $infile,
	  quorum   => $quorum,
	  shares   => $shares,
	  width    => $width,
	  filespec => $filespec,
	  rand     => $rand,
	  bufsize  => $bufsize,
	  n_chunks => $n_chunks,
	  in_chunk_size  => $in_chunk_size,
	  out_chunk_size => $out_chunk_size,
	  out_file_size  => $out_file_size
	);
