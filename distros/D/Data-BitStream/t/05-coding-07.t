#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib qw(t/lib);
use BitStreamTest;

my @implementations = impl_list;
my @encodings       = encoding_list;

plan tests => scalar @encodings;

foreach my $encoding (@encodings) {
  subtest "$encoding" => sub { test_encoding($encoding); };
}
done_testing();


sub test_encoding {
  my $encoding = shift;

  plan tests => scalar @implementations;

  foreach my $type (@implementations) {
    my @data = (0, 4, 5, 10, 317, 12, 3, 8, 7, 213);
    my $stream = stream_encode_array($type, $encoding, @data);
    BAIL_OUT("No stream of type $type") unless defined $stream;
    my @v = stream_decode_array($encoding, $stream);
    is_deeply( \@v, \@data, "$encoding store simple array using $type");
  }
}
