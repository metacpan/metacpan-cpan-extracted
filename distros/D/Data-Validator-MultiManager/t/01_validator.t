#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More;
use Test::Deep;

use Data::Validator;
use Data::Validator::MultiManager;

my $manager = Data::Validator::MultiManager->new;
$manager->add(
    collection => {
        id => { isa => 'ArrayRef' },
    },
    entry => {
        id => { isa => 'Int' },
    },
);

subtest 'collection' => sub {
    my $result = $manager->validate({ id => [1, 2] });

    ok $result->valid;
    is $result->valid, 'collection';
    cmp_deeply $result->values, { id => [1, 2] };
};

subtest 'entry' => sub {
    my $result = $manager->validate({ id => 1 });

    ok $result->valid;
    is $result->valid, 'entry';
    cmp_deeply $result->values, { id => 1 };
};

subtest 'fail' => sub {
    my $result = $manager->validate({ id => 'aaa' });

    ok not $result->valid;
    cmp_deeply $result->error('entry'), superhashof( { name => 'id', type => 'InvalidValue' } );
    cmp_deeply $result->error('collection'), superhashof( { name => 'id', type => 'InvalidValue' } );
    ok not $result->values;
};

done_testing;
