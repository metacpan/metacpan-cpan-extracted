use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'each_value';

use Scalar::Util 'refaddr';

subtest 'test the each_value method' => sub {
    my $array = Data::Object::Array->new(['a'..'g']);

    my $values = [];
    my @argument = (sub{ push @{$values}, shift });
    my $each_value = $array->each_value(@argument);

    is refaddr($array), refaddr($each_value);
    is_deeply $each_value, $array;
    is_deeply $values, [qw(a b c d e f g)];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $each_value, 'Data::Object::Array';
};

ok 1 and done_testing;
