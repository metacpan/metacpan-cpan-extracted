use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'keys';

use Scalar::Util 'refaddr';

subtest 'test the keys method' => sub {
    my $hash = Data::Object::Hash->new({1..8});

    my @argument = ();
    my $keys = $hash->keys(@argument);

    isnt refaddr($hash), refaddr($keys);
    is_deeply [sort @$keys], [1,3,5,7];

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $keys, 'Data::Object::Array';
};

ok 1 and done_testing;
