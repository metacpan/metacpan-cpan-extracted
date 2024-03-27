#!/usr/bin/perl

# LZHD compressor/decompressor.

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
        lzhd_compress($chunk, $out_fh);
    }
}

sub decompress ($fh, $out_fh) {
    while (!eof($fh)) {
        lzhd_decompress($fh, $out_fh);
    }
}

$opts{d} ? decompress(\*STDIN, \*STDOUT) : compress(\*STDIN, \*STDOUT);
