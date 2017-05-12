use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'length';

use Scalar::Util 'refaddr';

subtest 'test the length method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ();
    my $length = $array->length(@argument);

    isnt refaddr($array), refaddr($length);
    is $length, 5;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $length, 'Data::Object::Number';
};

ok 1 and done_testing;
