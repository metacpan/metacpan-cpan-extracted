use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'size';

use Scalar::Util 'refaddr';

subtest 'test the size method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ();
    my $size = $array->size(@argument);

    isnt refaddr($array), refaddr($size);
    is $size, 5;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $size, 'Data::Object::Number';
};

ok 1 and done_testing;
