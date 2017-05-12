use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'fold';

use Scalar::Util 'refaddr';

subtest 'test the fold method' => sub {
    my $hash = Data::Object::Hash->new({5,[4,5,6],7,{8,8,9,9,0,bless{1,2}}});
    my $fold = $hash->fold;

    isnt refaddr($hash), refaddr($fold);
    is_deeply $fold, {
        '5:0' => 4,
        '5:1' => 5,
        '5:2' => 6,
        '7.8' => 8,
        '7.9' => 9,
        '7.0' => bless{1,2},
    };

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $fold, 'Data::Object::Hash';
};

subtest 'test the fold method' => sub {
    my $hash = Data::Object::Hash->new({5,[4,{5,6}],7,{8,8,9,9,0,bless{1,2}}});
    my $fold = $hash->fold;

    isnt refaddr($hash), refaddr($fold);
    is_deeply $fold, {
        '5:0'   => 4,
        '5:1.5' => 6,
        '7.8'   => 8,
        '7.9'   => 9,
        '7.0'   => bless{1,2},
    };

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $fold, 'Data::Object::Hash';
};

ok 1 and done_testing;
