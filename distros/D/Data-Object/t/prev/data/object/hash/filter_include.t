use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'filter_include';

use Scalar::Util 'refaddr';

subtest 'test the filter_include method' => sub {
    my $hash = Data::Object::Hash->new({1..8});

    my @argument = (1,3);
    my $filter_include = $hash->filter_include(@argument);

    isnt refaddr($hash), refaddr($filter_include);
    is_deeply $filter_include, {1=>2,3=>4};

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $filter_include, 'Data::Object::Hash';
};

ok 1 and done_testing;
