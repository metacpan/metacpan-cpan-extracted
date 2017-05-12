#!/usr/bin/perl -w

use strict;
use Test;
BEGIN { plan tests => 2, todo => [] }

use Data::PropertyList qw( astext fromtext );

my ($original, $astext, $fromtext, $comparison);

# Stringify Array of Hashes

$original = [
  { 'id' => 9, 'name' => 'max' },
  { 'id' => 2, 'name' => 'ben' },
  { 'id' => 7, 'name' => 'archer' },
];

$astext = astext( $original, '-drefs' => 0 );

# warn $astext;

$comparison = "{\n  id = 9;\n  name = max;\n},\n" . 
	      "{\n  id = 2;\n  name = ben;\n},\n" . 
	      "{\n  id = 7;\n  name = archer;\n},\n";

ok( $astext eq $comparison );

# Destringify Array of Hashes

$astext = astext( $original, '-drefs' => 1 );
$comparison = fromtext( $astext, '-array' => 1, '-source'=> 'test data' );

ok( ! grep { 
  $original->[$_]{'id'} ne $comparison->[$_]{'id'} or
  $original->[$_]{'name'} ne $comparison->[$_]{'name'}
} ( 0 .. $#$original ) );
