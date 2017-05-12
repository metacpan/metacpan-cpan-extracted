#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use Compress::Huffman::Binary ':all';
my $input = 'something or another';
my $output = huffman_encode ($input);
my $roundtrip = huffman_decode ($output);
if ($input eq $roundtrip) {
    print "OK.\n";
}
else {
    print "FAIL!\n";
}
