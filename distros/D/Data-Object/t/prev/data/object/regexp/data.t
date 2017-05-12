use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Regexp';
can_ok 'Data::Object::Regexp', 'data';

subtest 'test the data method' => sub {
    my $re = Data::Object::Regexp->new(qr(test));
    is ref($re->data), 'Regexp', 'data() returns Regexp ref';
    like $re->data, qr{
        \(\?
            (?:
                \^    # newer Perls use ^ when all flags are off
                |
                -xism # older Perls spell them all out
            )
        :test\)
    }x;
};

ok 1 and done_testing;
