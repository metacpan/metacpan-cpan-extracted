use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Scalar';
can_ok 'Data::Object::Scalar', 'data';

subtest 'test the data method' => sub {
    my $string = 'a string';
    my $scalar = Data::Object::Scalar->new(\$string);
    is $scalar->detract, $string;
};

ok 1 and done_testing;
