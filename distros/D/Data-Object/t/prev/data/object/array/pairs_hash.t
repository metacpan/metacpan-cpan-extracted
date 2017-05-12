use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'pairs_hash';

use Scalar::Util 'refaddr';

subtest 'test the pairs_hash method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ();
    my $pairs_hash = $array->pairs_hash(@argument);

    isnt refaddr($array), refaddr($pairs_hash);
    is_deeply $pairs_hash, {0=>1,1=>2,2=>3,3=>4,4=>5};

    isa_ok $array, 'Data::Object::Array';
    isa_ok $pairs_hash, 'Data::Object::Hash';
};

ok 1 and done_testing;
