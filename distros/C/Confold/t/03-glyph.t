#!perl
# Spelling and placement of the glyph itself.
use 5.038;
use strict;
use warnings;
use Test::More;
use Confold;

plan tests => 12;

my $v = 5;

is( (<: 42),   42,  'space between glyph and operand' );
is( (<:42),    42,  'no space at all' );
is( (<:  42),  42,  'extra space' );
is( (<: -7),   -7,  'negative literal' );
is( (<:-7),    -7,  'negative literal, no space' );
is( (<: $v),    5,  'scalar operand' );
is( (<:$v),     5,  'scalar operand, no space' );
is( (<: "s"), 's',  'string operand' );
is( (<:"s"),  's',  'string operand, no space' );

# Across a line break, and past a comment.
my $split = <:
    99;
is $split, 99, 'operand on the following line';

my $commented = <: # a comment between glyph and operand
    17;
is $commented, 17, 'comment between glyph and operand';

# Several on one line.
my @many = (<: 1, <: 2, <: 3);
is "@many", '1 2 3', 'several on one line';
