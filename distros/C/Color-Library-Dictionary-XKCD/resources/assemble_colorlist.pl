#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Path::Tiny qw( path );
use Data::Dumper qw( Dumper );

my @colors;

sub _pp {
  my ($value) = @_;
  local $Data::Dumper::Terse     = 1;
  local $Data::Dumper::Purity    = 1;
  local $Data::Dumper::Useqq     = 0;
  local $Data::Dumper::Indent    = 0;
  local $Data::Dumper::Quotekeys = 0;
  return Dumper($value);
}

sub _pp_int {
  my ($value) = @_;
  my @out;
  while ( length $value > 3 ) {
    unshift @out, substr( $value, -3, 3, q[] );
  }
  if ( length $value ) {
    unshift @out, $value;
  }
  return join q[_], @out;
}

sub expand_color {
  my ( $title, $hexcolor ) = @_;
  my $name = $title;
  $name =~ s/\s+/_/g;
  my $id = "xkcd:$name";
  my ( $red, $green, $blue ) = map { hex $_ } grep { $_ } split /(..)/, $hexcolor;
  my $icolor = hex($hexcolor);
  return sprintf qq{[%-31s%-26s%-26s[%4d,%4d,%5d, ], %s, %9s, ],\n},
    _pp($id) . q[,], _pp($name) . q[,], _pp($title) . q[,], $red, $green, $blue, _pp("$hexcolor"), _pp_int($icolor);
}
my $index = 0;

for my $line ( path('.')->child('rgb.txt')->lines_utf8 ) {
  if ( $line =~ /^(.+?)\s+#([0-9a-f]{6})\s*$/ ) {
    my ( $title, $hexcolor ) = ( $1, $2 );
    print expand_color( $title,        $hexcolor );
    print expand_color( "xkcd $index", $hexcolor );
    $index++;
    next;
  }
  die "$line doesn't match regex";
}

