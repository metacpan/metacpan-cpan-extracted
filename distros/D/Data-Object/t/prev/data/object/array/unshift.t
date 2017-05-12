use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'unshift';

use Scalar::Util 'refaddr';

subtest 'test the unshift method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = (-2,-1,0);
    my $unshift = $array->unshift(@argument);

    is refaddr($array), refaddr($unshift);
    is_deeply $unshift, [-2,-1,0,1,2,3,4,5];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $unshift, 'Data::Object::Array';
};

ok 1 and done_testing;
