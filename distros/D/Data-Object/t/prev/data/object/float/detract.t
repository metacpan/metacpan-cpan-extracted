use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Float';
can_ok 'Data::Object::Float', 'detract';

subtest 'test the detract method' => sub {
    my $float = Data::Object::Float->new(3.99);
    is $float->detract, 3.99;

    $float = Data::Object::Float->new('9.99');
    is "$float", '9.99';
};

ok 1 and done_testing;
