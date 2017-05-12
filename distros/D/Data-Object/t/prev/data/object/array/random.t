use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'random';

use Scalar::Util 'refaddr';

subtest 'test the random method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    for (1..50) {
        my $random = $array->random;
        isnt refaddr($array), refaddr($random);
        ok $random <= 5;

        isa_ok $array, 'Data::Object::Array';
        isa_ok $random, 'Data::Object::Number';
    }
};

ok 1 and done_testing;
