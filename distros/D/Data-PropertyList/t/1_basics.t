#!/usr/bin/perl -w

use strict;
use Test;
BEGIN { plan tests => 6, todo => [] }

use Data::PropertyList qw( astext fromtext );

my( @Arrays, @Hashes );

@Arrays = (
  [ ],
  [ 0 .. 255 ],
  [ 'foo', 'bar', 'baz', ],
);

@Hashes = (
  { },
  { map { chr($_), $_ } (0 .. 255) },
  { 'foo' => 'bar', 'baz' => 0 },
);

# Stringify Array

foreach ( @Arrays ) {
  ok( astext($_, '-drefs'=>0) eq join '', map "$_\,\n", @$_ );
}

foreach ( @Arrays ) {
  ok( astext($_, '-drefs'=>0, '-maxitems'=>999) eq join '', map "$_\, ", @$_ );
}
