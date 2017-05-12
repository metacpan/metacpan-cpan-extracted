use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'slice';

use Scalar::Util 'refaddr';

subtest 'test the slice method' => sub {
    my $hash = Data::Object::Hash->new({1..8});

    my @argument = (1,3);
    my $slice = $hash->slice(@argument);

    isnt refaddr($hash), refaddr($slice);
    is_deeply $slice, {1=>2,3=>4};

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $slice, 'Data::Object::Hash';
};

ok 1 and done_testing;
