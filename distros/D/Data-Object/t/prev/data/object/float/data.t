use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Float';
can_ok 'Data::Object::Float', 'data';

subtest 'test the data method' => sub {
    my $float = Data::Object::Float->new(3.99);
    is $float->data, 3.99;

    $float = Data::Object::Float->new('9.99');
    is "$float", '9.99';
};

ok 1 and done_testing;
