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
    my $stream = new_stream($type);
    BAIL_OUT("No stream of type $type") unless defined $stream;
    my ($esub, $dsub, $param) = sub_for_string($encoding);
    BAIL_OUT("No sub for encoding $encoding") unless defined $esub and defined $dsub;
    $esub->($stream, $param, 1234);
    $stream->rewind_for_read;
    my $v = $dsub->($stream, $param);
    cmp_ok($v, '==', 1234, "$encoding constant 1234 using $type");
  }
}
