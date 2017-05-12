use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'pairs';

use Scalar::Util 'refaddr';

subtest 'test the pairs method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ();
    my $pairs = $array->pairs(@argument);

    isnt refaddr($array), refaddr($pairs);
    is_deeply $pairs, [[0,1],[1,2],[2,3],[3,4],[4,5]];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $pairs, 'Data::Object::Array';
};

ok 1 and done_testing;
