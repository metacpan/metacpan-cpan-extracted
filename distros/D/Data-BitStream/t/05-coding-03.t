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
    my $stream = stream_encode_array($type, $encoding, 0);
    BAIL_OUT("No stream of type $type") unless defined $stream;
    my @v = stream_decode_array($encoding, $stream);
    ok( (scalar @v == 1) && ($v[0] == 0) , "$encoding stream 0 using $type");
  }
}
