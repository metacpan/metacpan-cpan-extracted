use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'to';

use Scalar::Util 'refaddr';

subtest 'test the to method' => sub {
    my $integer = Data::Object::Number->new(-5);
    my $to = $integer->to(5);

    isnt refaddr($integer), refaddr($to);
    is_deeply $to, [-5,-4,-3,-2,-1, 0,1,2,3,4,5];

    isa_ok $integer, 'Data::Object::Number';
    isa_ok $to, 'Data::Object::Array';
};

subtest 'test the to method - ascending' => sub {
    my $integer = Data::Object::Number->new(0);
    my $to = $integer->to(5);

    isnt refaddr($integer), refaddr($to);
    is_deeply $to, [0,1,2,3,4,5];

    isa_ok $integer, 'Data::Object::Number';
    isa_ok $to, 'Data::Object::Array';
};

subtest 'test the to method - descending' => sub {
    my $integer = Data::Object::Number->new(5);
    my $to = $integer->to(0);

    isnt refaddr($integer), refaddr($to);
    is_deeply $to, [5,4,3,2,1,0];

    isa_ok $integer, 'Data::Object::Number';
    isa_ok $to, 'Data::Object::Array';
};

ok 1 and done_testing;
