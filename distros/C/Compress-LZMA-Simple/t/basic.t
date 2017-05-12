#! /usr/bin/perl

use lib qw(./blib/lib ./blib/arch .);
use ExtUtils::testlib;
use strict;
use warnings;
use Test::More qw(no_plan);
use Compress::LZMA::Simple qw(compress decompress);

my $raw = "The LZMA uses an improved LZ77 compression algorithm, backed by a range encoder.  Streams for data, repeated-sequence size and repeated-sequence location seem to be compressed separately.";

my $enc = Compress::LZMA::Simple::compress($raw);
my $dec = Compress::LZMA::Simple::decompress($enc);
ok($raw eq $dec, "scalar");

$enc = compress(\$raw);
$dec = decompress($enc);
ok($raw eq $$dec, "reference");
