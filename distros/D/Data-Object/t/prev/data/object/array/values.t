use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'values';

use Scalar::Util 'refaddr';

subtest 'test the values method' => sub {
    my $array = Data::Object::Array->new(['a'..'d']);
    my $values = $array->values;

    isnt refaddr($array), refaddr($values);
    is_deeply $values, ['a'..'d'];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $values, 'Data::Object::Array';
};

ok 1 and done_testing;
