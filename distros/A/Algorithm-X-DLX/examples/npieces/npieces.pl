#!/usr/bin/perl

use strict;
use warnings;

use NPieces;

if (@ARGV != 4) {
  die "Usage: $0 <width> <height> <knights> <queens>\n";
}

my ($width, $height, $knights, $queens) = map { int($_) } @ARGV;

my $npieces = NPieces->new(
  width   => $width,   height => $height, 
  knights => $knights, queens => $queens);

my %chr = ( 
  NPieces::None   => '.', 
  NPieces::Knight => 'N', 
  NPieces::Queen  => 'Q'
);

my $i = 0;

while (my $solution = $npieces->next_solution()) {
  $i++;
  print "Solution $i\n";

  foreach my $row (@$solution) {
    foreach my $piece (@$row) {
      print $chr{$piece . ''};
    }
    print "\n";
  }
  print "\n";
}

print "Solutions for ${width}x${height}, N=${knights}, Q=${queens}: $i\n";

