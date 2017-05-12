#!/usr/bin/perl
#
# Make sure we can "use" every module

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
  package main;

  use File::Find::Rule;
  @classes = map { my $x = $_;
      $x =~ s|^blib/lib/||;
      $x =~ s|/|::|g;
      $x =~ s|\.pm$||;
      $x;
    } File::Find::Rule->file()->name( '*.pm' )->in( 'blib' );
}

use Test::More tests => scalar @classes;

foreach my $class ( @classes ) {
  use_ok( $class );
}
