use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'filter_exclude';

use Scalar::Util 'refaddr';

subtest 'test the filter_exclude method' => sub {
    my $hash = Data::Object::Hash->new({1..8});

    my @argument = (1,3);
    my $filter_exclude = $hash->filter_exclude(@argument);

    isnt refaddr($hash), refaddr($filter_exclude);
    is_deeply $filter_exclude, {5=>6,7=>8};

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $filter_exclude, 'Data::Object::Hash';
};

ok 1 and done_testing;
