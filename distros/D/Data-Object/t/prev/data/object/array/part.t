use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'part';

use Scalar::Util 'refaddr';

subtest 'test the part method' => sub {
    my $array = Data::Object::Array->new([1..10]);

    my @argument = (sub { shift > 5 });
    my $part = $array->part(@argument);

    isnt refaddr($array), refaddr($part);
    is_deeply $part, [[6, 7, 8, 9, 10], [1, 2, 3, 4, 5]];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $part, 'Data::Object::Array';
};

ok 1 and done_testing;
