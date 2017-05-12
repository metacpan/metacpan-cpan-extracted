use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'pop';

use Scalar::Util 'refaddr';

subtest 'test the pop method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ();
    my $pop = $array->pop(@argument);

    isnt refaddr($array), refaddr($pop);
    is $pop, 5;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $pop, 'Data::Object::Number';
};

ok 1 and done_testing;
