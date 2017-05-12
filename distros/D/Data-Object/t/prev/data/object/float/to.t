use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Float';
can_ok 'Data::Object::Float', 'to';

use Scalar::Util 'refaddr';

subtest 'test the to method' => sub {
    my $float = Data::Object::Float->new(-5.49);
    my $to = $float->to(5);

    isnt refaddr($float), refaddr($to);
    is_deeply $to, [-5,-4,-3,-2,-1, 0,1,2,3,4,5];

    isa_ok $float, 'Data::Object::Float';
    isa_ok $to, 'Data::Object::Array';
};

subtest 'test the to method - ascending' => sub {
    my $float = Data::Object::Float->new(0.99);
    my $to = $float->to(5);

    isnt refaddr($float), refaddr($to);
    is_deeply $to, [0,1,2,3,4,5];

    isa_ok $float, 'Data::Object::Float';
    isa_ok $to, 'Data::Object::Array';
};

subtest 'test the to method - descending' => sub {
    my $float = Data::Object::Float->new(5.0);
    my $to = $float->to(0);

    isnt refaddr($float), refaddr($to);
    is_deeply $to, [5,4,3,2,1,0];

    isa_ok $float, 'Data::Object::Float';
    isa_ok $to, 'Data::Object::Array';
};

ok 1 and done_testing;
