#!/usr/bin/perl

# Bzip2-like compressor/decompressor, using symbolic BWT (although, unnecessary here).

# usage:
#   perl script.pl < input.txt > compressed.enc
#   perl script.pl -d < compressed.enc > decompressed.txt

use 5.036;
use lib               qw(../lib);
use Getopt::Std       qw(getopts);
use Compression::Util qw(:all);

use constant {CHUNK_SIZE => 1 << 17};

local $Compression::Util::VERBOSE = 0;

getopts('d', \my %opts);

sub compress ($fh, $out_fh) {
    while (read($fh, (my $chunk), CHUNK_SIZE)) {
        print $out_fh bz2_compress_symbolic(string2symbols($chunk));
    }
}

sub decompress ($fh, $out_fh) {
    while (!eof($fh)) {
        print $out_fh symbols2string(bz2_decompress_symbolic($fh));
    }
}

$opts{d} ? decompress(\*STDIN, \*STDOUT) : compress(\*STDIN, \*STDOUT);
