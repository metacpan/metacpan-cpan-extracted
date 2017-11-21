#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Enumerable::Lazy;
use Data::Dumper;

{

  use List::Util qw(reduce);
  use bytes;

  my $file_path = 'README';
  open(my $fh, '<:raw', $file_path)
    or die sprintf('Unable to open %s', $file_path);

  my $file_stream = Data::Enumerable::Lazy->from_bin_file($fh, { is_finite => 1, });
  my $chunks = $file_stream->to_list;
  my $total_size = reduce { $a + bytes::length($b) } 0, @$chunks;

  close($fh);

  my @stat = stat($file_path);
  is $total_size, $stat[7];
}

done_testing;
