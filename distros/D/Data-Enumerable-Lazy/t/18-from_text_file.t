#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Enumerable::Lazy;
use Data::Dumper;

{
  my $file_path = 'README';
  open(my $fh, '<', $file_path)
    or die sprintf('Unable to open %s', $file_path);

  my $file_stream = Data::Enumerable::Lazy->from_text_file($fh, { is_finite => 1, });
  my $cnt = 10;
  my $lines = $file_stream->take($cnt);

  close($fh);

  is scalar(@$lines), $cnt;

  for my $line (@$lines) {
    is substr($line, -1, 1), "\n";
  }
}

{
  my $file_path = 'README';
  open(my $fh, '<', $file_path)
    or die sprintf('Unable to open %s', $file_path);

  my $file_stream = Data::Enumerable::Lazy->from_text_file($fh, { is_finite => 1, chomp => 1, });
  my $cnt = 10;
  my $lines = $file_stream->take($cnt);

  close($fh);

  is scalar(@$lines), $cnt;

  for my $line (@$lines) {
    is index($line, "\n"), -1;
  }
}

done_testing;
