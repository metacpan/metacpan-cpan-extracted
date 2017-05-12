#!/usr/bin/env perl
use warnings;
use strict;

# Test "sane" usage

require Test::More;

use Acme::Globule qw( Range );

my @tests = (
    '1..5' => [ 1..5 ],
    '5..1' => [ reverse 1..5 ],
    '1..1' => [ 1 ],

    '-2..2' => [ -2..2 ],
    '2..-2' => [ reverse -2..2 ],

    '1,2..5' => [ 1..5 ],
    '1,3..7' => [ 1, 3, 5, 7 ],
    '1,3..8' => [ 1, 3, 5, 7 ], # don't do this...

    '5,4..1' => [ reverse 1..5 ],
    '7,5..1' => [ 7, 5, 3, 1 ],
    '8,6..1' => [ 8, 6, 4, 2 ], # don't do this...

    '1..4,5' => [ 1..5 ],
    '1..5,7' => [ 1, 3, 5, 7 ],
    '1..6,8' => [ 1, 3, 5, 7 ], # don't do this...

    '5..2,1' => [ reverse 1..5 ],
    '7..3,1' => [ 7, 5, 3, 1 ],
    '8..3,1' => [ 8, 6, 4, 2 ], # don't do this...

    # And really don't do these (they should probably die or give a
    # diagnostic):

    '1,1..5' => [ 1 ],
    '2,1..5' => [ ],
    '5..1,2' => [ ],

    # tests that an invalid range pattern passes through
    '1...1' => [ '1...1' ],
);

Test::More->import(tests => @tests/2);

while (my ($test, $expected) = splice @tests, 0, 2) {
    is_deeply( [eval "<$test>"], $expected, "$test worked" );
}
