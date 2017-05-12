use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'tail';

use Scalar::Util 'refaddr';

subtest 'test the tail method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ();
    my $tail = $array->tail(@argument);

    isnt refaddr($array), refaddr($tail);
    is_deeply $tail, [2,3,4,5];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $tail, 'Data::Object::Array';
};

ok 1 and done_testing;
