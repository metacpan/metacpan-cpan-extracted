package Compress::Huffman::Binary;
use warnings;
use strict;
use Carp;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/huffman_encode huffman_decode/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.01';
require XSLoader;
XSLoader::load ('Compress::Huffman::Binary', $VERSION);
1;
