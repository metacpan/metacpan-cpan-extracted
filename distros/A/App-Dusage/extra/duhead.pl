#!/usr/bin/perl

# Quickie to post-process the output of duage and show the
# entries that grew most.

use strict;
use warnings;

my $lines;
while ( <> ) {
#  122160   +43404  -142272  .retro-test

      my @a = /([ \d].{8})([-+ \d]{9})([-+ \d]{9})/;
      next unless defined $a[0] && defined $a[1];
      next if $a[1] =~ /-/;
      next if $a[0] =~ /^\s+/ && $a[2] =~ /^\s+$/;
      $a[1] = '+'.(0+$a[0]) if $a[1] !~ /\d/;
      next if $a[1] == 0;
      push( @$lines, [ $a[1], $_ ] );
}

@$lines = sort { $b->[0] <=> $a->[0] } @$lines;

print $_->[1] foreach @$lines;
