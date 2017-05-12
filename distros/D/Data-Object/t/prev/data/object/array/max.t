use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'max';

use Scalar::Util 'refaddr';

subtest 'test the max method' => sub {
    my $array = Data::Object::Array->new([8,9,1,2,3,undef,4,5,{},[]]);

    my @argument = ();
    my $max = $array->max(@argument);

    isnt refaddr($array), refaddr($max);
    is $max, 9;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $max, 'Data::Object::Number';
};

ok 1 and done_testing;
