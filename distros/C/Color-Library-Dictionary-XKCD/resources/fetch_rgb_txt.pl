#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Fetch;
my $uri = 'http://xkcd.com/color/rgb.txt';
my $ff = File::Fetch->new( uri => $uri, output_file => './rgb.txt' );
if ($ff) {
  my $where = $ff->fetch();
  print "$where";
}

