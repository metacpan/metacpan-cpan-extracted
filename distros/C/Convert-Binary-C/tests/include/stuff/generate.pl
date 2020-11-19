#!/usr/bin/perl -w
use strict;
use warnings;
use IO::File;
use File::Spec;

my $dir = shift // '.';

for my $f ('aa' .. 'az') {
  my $fh = IO::File->new(">" . File::Spec->catfile($dir, "$f.h")) or die;
  print $fh "/*\n";
  for (1..2500) {
    print $fh $f x 36, "\n";
  }
  print $fh "*/\n";
}
