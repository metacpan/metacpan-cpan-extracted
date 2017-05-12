use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'delete';

use Scalar::Util 'refaddr';

subtest 'test the delete method' => sub {
    my $array = Data::Object::Array->new([1..5]);
    my $delete = $array->delete(3);

    isnt refaddr($array), refaddr($delete);
    is $delete, 4;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $delete, 'Data::Object::Number';
};

ok 1 and done_testing;
