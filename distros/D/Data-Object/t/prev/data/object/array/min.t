use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'min';

use Scalar::Util 'refaddr';

subtest 'test the min method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ([8,9,1,2,3,undef,4,5,{},[]]);
    my $min = $array->min(@argument);

    isnt refaddr($array), refaddr($min);
    is $min, 1;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $min, 'Data::Object::Number';
};

ok 1 and done_testing;
