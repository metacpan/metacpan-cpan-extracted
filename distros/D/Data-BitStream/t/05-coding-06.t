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
    my $stream1 = new_stream($type);
    BAIL_OUT("No stream of type $type") unless defined $stream1;
    my $stream2 = new_stream($type);
    BAIL_OUT("No stream of type $type") unless defined $stream2;
    my ($esub, $dsub, $param) = sub_for_string($encoding);
    BAIL_OUT("No sub for encoding $encoding") unless defined $esub and defined $dsub;
    my $success = 1;
    my @data = (0 .. 67, 81, 96, 107, 127, 128, 129, 255, 256, 257, 510, 511, 512, 513);
    foreach my $n (@data) {
      # 1. Write value into stream1
      $stream1->erase_for_write;
      $esub->($stream1, $param, $n);
      # 2. Get the binary string from stream1
      my $str = $stream1->to_string();
      my $len = $stream1->len;
      $success = 0 if length($str) != $len;

      # 3. Set stream2 to the binary string.
      $stream2->from_string($str, $len);
      $success = 0 if $len != $stream2->len;

      # 4. Read value from stream2.  Ensure it matches what we wrote.
      $stream2->rewind_for_read;
      my $v = $dsub->($stream2, $param);
      $success = 0 if $v != $n;
      last unless $success;
    }
    ok($success, "$encoding put/get strings from 0 to 513");
  }
}
