#!/usr/bin/perl -w

use strict;
use Test;

# Some tests waiting on corrected escape handling in String::Escape
BEGIN { plan tests => 30, todo => [ 24, 25, 29, 30 ] }

use Data::PropertyList qw( astext fromtext );

my( @Simple, @Words, @Escapes );

@Simple = ( 
  'a', 
  'OneWord', 
  'Thequickbrownfox', 
  23238, 
  3.25 
);

@Words = ( 
  '', 
  'Two Words', 
  '/:>', 
  'Hey--you!', 
  'The quick brown fox.' 
);

@Escapes = (
  '\\n', 
  'One\\tTwo', 
  'The time is \\"now.\\"', 
  '\\x00', 
  'The time is \\xAAnow.\\xBA' 
);

# Simple values directly stringified
foreach ( @Simple ) {
  ok( $_ eq astext( $_ ) ); 
}
foreach (@Simple) {
  ok( $_ eq fromtext( $_, '-scalar' =>1 ) );
}

# Empty values, spaces or punctuation are enclosed in doublequotes
foreach ( @Words ) {
  ok( '"' . $_ . '"' eq astext( $_ ) );
}
foreach ( @Words ) {
  ok( $_ eq fromtext('"' . $_ . '"', '-scalar' =>1 ) );
}

# Nonprintable and high-bit characters are escaped with backslashes.
foreach ( @Escapes ) {
  ok( '"'.$_.'"' eq astext( eval '"'.$_.'"' ) );
}
foreach ( @Escapes ) {
  ok( eval('"'.$_.'"') eq fromtext( '"'.$_.'"', '-scalar' =>1 ) );
}
