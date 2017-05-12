use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'sort';

use Scalar::Util 'refaddr';

subtest 'test the sort method' => sub {
    my $array = Data::Object::Array->new(['d','c','b','a']);

    my @argument = ();
    my $sort = $array->sort(@argument);

    isnt refaddr($array), refaddr($sort);
    is_deeply $sort, ['a','b','c','d'];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $sort, 'Data::Object::Array';
};

ok 1 and done_testing;
