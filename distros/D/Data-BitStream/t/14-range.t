#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use List::Util qw(shuffle);
use lib qw(t/lib);
use BitStreamTest;

my $maxval = ~0;
my $skip64 = 0;  # allows skipping certain tests if we're on broken 64-bit.
{
  # Force maxval to 0xFFFFFFFF if the stream is 32-bit.
  my $stream = new_stream('String');
  $maxval = 0xFFFFFFFF if $stream->maxbits == 32;
  $skip64 = 1 if ($] < 5.008) && ($maxval < ~0);
}

my @maxdata = (0, 1, 2, 33, 65, 129,
               ($maxval >> 1) - 2,
               ($maxval >> 1) - 1,
               ($maxval >> 1),
               ($maxval >> 1) + 1,
               ($maxval >> 1) + 2,
               $maxval-2,
               $maxval-1,
               $maxval,
              );

push @maxdata, @maxdata;
@maxdata = shuffle @maxdata;


my @implementations = impl_list;
my @encodings = grep { is_universal($_) } encoding_list;
# Remove codings that cannot encode ~0
#@encodings = grep { $_ !~ /^(Omega|BVZeta)/i } @encodings;

plan tests => scalar @implementations * scalar @encodings;

foreach my $type (@implementations) {
  foreach my $encoding (@encodings) {
    SKIP: {
      # All fixed up, so no need to skip anything right now.
      # skip "Skipping range test: broken 64-bit Perl", 1
      #   if $skip64 && ($encoding =~ /^(Gamma|Delta|Omega|BVZeta)\b/);

      #print STDERR  "starting $type $encoding\n";
      my $stream = stream_encode_array($type, $encoding, @maxdata);
      my @v = stream_decode_array($encoding, $stream);
      is_deeply( \@v, \@maxdata, "$type: $encoding range patterns");
    }
  }
}
