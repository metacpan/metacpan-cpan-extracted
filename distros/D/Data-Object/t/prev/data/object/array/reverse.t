use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'reverse';

use Scalar::Util 'refaddr';

subtest 'test the reverse method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ();
    my $reverse = $array->reverse(@argument);

    isnt refaddr($array), refaddr($reverse);
    is_deeply $reverse, [5,4,3,2,1];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $reverse, 'Data::Object::Array';
};

ok 1 and done_testing;
