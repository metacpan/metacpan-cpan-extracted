use strict;
use warnings;
use Test::More;

plan skip_all => 'Missing implicit dependencies. Tests skipped.' unless eval q(
    require Data::Object::Hash;
    1;
);

use Data::Object 'type_hash';
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'type_hash';

subtest 'test the type_hash function' => sub {
    my $hash1 = type_hash {1..4};
    my $hash2 = type_hash {1..4};
    isa_ok $hash1, 'Data::Object::Hash';
    isa_ok $hash2, 'Data::Object::Hash';
    isnt refaddr($hash1), refaddr($hash2);
};

ok 1 and done_testing;
