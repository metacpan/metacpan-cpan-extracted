#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Path::Tiny qw( path );
use Data::Dump qw( pp );

my @colors;

sub expand_color {
  my ( $title, $hexcolor ) = @_;
  my $name = $title;
  $name =~ s/\s+/_/g;
  my $id = "xkcd:$name";
  my ( $red, $green, $blue ) = map { hex $_ } grep { $_ } split /(..)/, $hexcolor;
  my $icolor = hex($hexcolor);
  return [ $id, $name, $title, [ $red, $green, $blue ], "$hexcolor", $icolor ];
}
my $index = 0;

my $labelids = {};

for my $line ( path('.')->child('rgb.txt')->lines_utf8 ) {
  if ( $line =~ /^(.+?)\s+#([0-9a-f]{6})\s*$/ ) {
    my ( $title, $hexcolor ) = ( $1, $2 );
    $labelids->{$title} = $index;
    push @colors, expand_color( $title, $hexcolor );

    #            expand_color( "xkcd $index", $hexcolor );
    $index++;
    next;
  }
  die "$line doesn't match regex";
}

for my $color ( sort { $a->[0] cmp $b->[0] } @colors ) {
  my $left = sprintf '%-25s -> %s ( xkcd_%-s )', $color->[2], $color->[1], $labelids->{ $color->[2] };
  printf "    %-70s -> #%s\n", $left, $color->[4];
}
