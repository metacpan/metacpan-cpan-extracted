#!/usr/bin/perl
#
# Make sure every module contains 'use strict'

use strict;
use warnings;
our @classes;

BEGIN {
  eval {
    require File::Find::Rule;
  };
  if ($@) {
    print "1..0 # Skipped - do not have File::Find::Rule installed\n";
    exit;
  }
}


BEGIN {
  use File::Find::Rule;
  @classes = File::Find::Rule->file()->name('*.pm')->in('lib');
}

use Test::More tests => scalar @classes;

foreach my $class ( @classes ) {
  my $fh;
  local $/ = undef;
  open $fh, $class;
  my $file = <$fh>;
  ok($file =~ qr/use\s+strict/, $class);
}
