#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use C::Tokenize 'strip_comments';
my $c = <<EOF;
char * not_comment = "/* This is not a comment */";
int/* The X coordinate. */x;
/* The Y coordinate.
   See https://en.wikipedia.org/wiki/Cartesian_coordinates. */
int y;
// The Z coordinate.
int z;
EOF
print strip_comments ($c);
