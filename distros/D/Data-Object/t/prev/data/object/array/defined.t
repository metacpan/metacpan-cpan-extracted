use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'defined';

use Scalar::Util 'refaddr';

subtest 'test the defined method' => sub {
    my $array = Data::Object::Array->new([1,2,undef,4,5]);
    my $defined = $array->defined(2);

    isnt refaddr($array), refaddr($defined);
    is $defined, '';

    isa_ok $array, 'Data::Object::Array';
    isa_ok $defined, 'Data::Object::String';

    $defined = $array->defined(1);

    isnt refaddr($array), refaddr($defined);
    is $defined, 1;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $defined, 'Data::Object::Number';
};

ok 1 and done_testing;
