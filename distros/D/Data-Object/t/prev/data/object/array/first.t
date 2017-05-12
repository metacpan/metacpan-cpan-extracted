use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'first';

use Scalar::Util 'refaddr';

subtest 'test the first method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ();
    my $first = $array->first(@argument);

    isnt refaddr($array), refaddr($first);
    is $first, 1;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $first, 'Data::Object::Number';
};

ok 1 and done_testing;
