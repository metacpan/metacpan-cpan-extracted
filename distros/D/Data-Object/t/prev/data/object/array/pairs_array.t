use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'pairs_array';

use Scalar::Util 'refaddr';

subtest 'test the pairs_array method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ();
    my $pairs_array = $array->pairs_array(@argument);

    isnt refaddr($array), refaddr($pairs_array);
    is_deeply $pairs_array, [[0,1],[1,2],[2,3],[3,4],[4,5]];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $pairs_array, 'Data::Object::Array';
};

ok 1 and done_testing;
