#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use List::Util qw(shuffle);
use lib qw(t/lib);
use BitStreamTest;

my @implementations = impl_list;
my @encodings       = encoding_list;
plan tests =>   (scalar @implementations) * 1;

foreach my $type (@implementations) {

  srand(29);

  {
    my @data;
    foreach my $encoding (@encodings) {
      my $maxval = (is_universal($encoding)) ? 100_000_000 : 1000;
      push @data, [$encoding, int(rand($maxval))]   for (1 .. 100);
    }
    # @data will have 100 * scalar @encodings entries,
    # or about 3000 encoding/number pairs.
    @data = shuffle @data;
    # we're encoding a lot of random values, each using a different coding
    # method.  We should be be able to successfully retrieve them all.
    my $nvalues = scalar @data;
    my $stream = stream_encode_mixed($type, @data);
    my $success = stream_decode_mixed($stream, @data);
    ok($success, "$type: mixed coding with $nvalues values");
  }

  # test each parameter for parameterized codes
}

done_testing();
