use strict;
use warnings;
use 5.010;

use Test::More tests => 4;

use Boolean::String;

for my $original_string ( map { "$_ ..." } 0, 1 ) {
    for my $boolean_string ( map { $_->($original_string) } \&true, \&false ) {

        no warnings 'numeric';

        my $got      = 0 + $boolean_string;
        my $expected = 0 + $original_string;

        is $got, $expected, 'should be unaffected in numeric context';

    }
}

