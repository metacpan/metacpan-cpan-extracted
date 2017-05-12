use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'keys';

use Scalar::Util 'refaddr';

subtest 'test the keys method' => sub {
    my $array = Data::Object::Array->new(['a'..'d']);

    my @argument = ();
    my $keys = $array->keys(@argument);

    isnt refaddr($array), refaddr($keys);
    is_deeply $keys, [0,1,2,3];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $keys, 'Data::Object::Array';
};

ok 1 and done_testing;
