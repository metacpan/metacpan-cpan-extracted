use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'map';

use Scalar::Util 'refaddr';

subtest 'test the map method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my $values = [];
    my @argument = (sub { push @{$values}, shift() + 1 });
    my $map = $array->map(@argument);

    isnt refaddr($array), refaddr($map);
    is_deeply $values, [2,3,4,5,6];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $map, 'Data::Object::Array';
};

ok 1 and done_testing;
