use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'lookup';

use Scalar::Util 'refaddr';

subtest 'test the lookup method' => sub {
    my $hash = Data::Object::Hash->new({1..3,{
        4,{5,6,7,{8,9,10,11,"10.1",{1,2}}}}
    });

    isa_ok $hash, 'Data::Object::Hash';

    my $lookup = $hash->lookup('3.4.7');
    isnt refaddr($hash), refaddr($lookup);
    is_deeply $lookup, {8=>9,10=>11,"10.1"=>{1,2}};
    isa_ok $lookup, 'Data::Object::Hash';

    $lookup = $hash->lookup('3.4');
    isnt refaddr($hash), refaddr($lookup);
    is_deeply $lookup, {5=>6,7=>{8=>9,10=>11,"10.1"=>{1,2}}};
    isa_ok $lookup, 'Data::Object::Hash';

    $lookup = $hash->lookup(2);
    isnt refaddr($hash), refaddr($lookup);
    is_deeply $lookup, undef;
    isa_ok $lookup, 'Data::Object::Undef';

    $lookup = $hash->lookup(1);
    isnt refaddr($hash), refaddr($lookup);
    is_deeply $lookup, 2;
    isa_ok $lookup, 'Data::Object::Number';

    $lookup = $hash->lookup('3.4.7.10.1.1');
    isnt refaddr($hash), refaddr($lookup);
    is_deeply $lookup, 2;
    isa_ok $lookup, 'Data::Object::Number';

    $lookup = $hash->lookup('3.4.7.10.1');
    isnt refaddr($hash), refaddr($lookup);
    is_deeply $lookup, {1,2};
    isa_ok $lookup, 'Data::Object::Hash';
};

ok 1 and done_testing;
