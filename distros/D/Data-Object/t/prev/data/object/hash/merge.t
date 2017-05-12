use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'merge';

use Scalar::Util 'refaddr';

subtest 'test the merge method' => sub {
    my $hash = Data::Object::Hash->new({1..8});

    my @argument = ({7,7,9,9});
    my $merge = $hash->merge(@argument);

    isnt refaddr($hash), refaddr($merge);
    is_deeply $merge, {1=>2,3=>4,5=>6,7=>7,9=>9};

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $merge, 'Data::Object::Hash';
};

subtest 'test the merge method - arrayref value' => sub {
    my $hash = Data::Object::Hash->new({1,2,3,4});

    my @argument = ({3,[4,5]});
    my $merge = $hash->merge(@argument);

    isnt refaddr($hash), refaddr($merge);
    is_deeply $merge, {1=>2,3=>[4,5]};

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $merge, 'Data::Object::Hash';
};

subtest 'test the merge method - arrayref value' => sub {
    my $hash = Data::Object::Hash->new({1,2,3,[4,5]});

    my @argument = ({3,{4,5}});
    my $merge = $hash->merge(@argument);

    isnt refaddr($hash), refaddr($merge);
    is_deeply $merge, {1=>2,3=>{4,5}};

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $merge, 'Data::Object::Hash';
};

subtest 'test the merge method - undef value' => sub {
    my $hash = Data::Object::Hash->new({1,2,3,{4,5}});

    my @argument = ({3,undef});
    my $merge = $hash->merge(@argument);

    isnt refaddr($hash), refaddr($merge);
    is_deeply $merge, {1=>2,3=>undef};

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $merge, 'Data::Object::Hash';
};

ok 1 and done_testing;
