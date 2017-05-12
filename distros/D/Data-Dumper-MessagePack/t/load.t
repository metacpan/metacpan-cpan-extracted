#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  Data::Dumper::MessagePack
)) {
  use_ok($_);
}

done_testing;

