use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'list';

use Scalar::Util 'refaddr';

subtest 'test the list method - scalar context' => sub {
    my $array = Data::Object::Array->new(['a'..'d']);
    my $values = $array->list;

    isnt refaddr($array), refaddr($values);
    is_deeply $values, ['a'..'d'];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $values, 'Data::Object::Array';
};

subtest 'test the list method - list context' => sub {
    my $array = Data::Object::Array->new(['a'..'d']);
    my @values = $array->list;

    is_deeply \@values, ['a'..'d'];

    is $values[0], 'a';
    isa_ok $values[0], 'Data::Object::String';

    is $values[1], 'b';
    isa_ok $values[1], 'Data::Object::String';

    is $values[2], 'c';
    isa_ok $values[2], 'Data::Object::String';

    is $values[3], 'd';
    isa_ok $values[3], 'Data::Object::String';

    isa_ok $array, 'Data::Object::Array';
};

ok 1 and done_testing;
