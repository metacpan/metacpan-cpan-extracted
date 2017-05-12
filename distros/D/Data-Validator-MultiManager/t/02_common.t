#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More;
use Test::Deep;

use Data::Validator::MultiManager;

my $manager = Data::Validator::MultiManager->new;
$manager->common(
    category => { isa => 'Int' },
);
$manager->add(
    collection => {
        id => { isa => 'ArrayRef' },
    },
    entry => {
        id => { isa => 'Int' },
    },
);

subtest 'collection' => sub {
    my $result = $manager->validate({
        category => 1,
        id       => [1,2],
    });
    is $result->valid, 'collection';
};

subtest 'entry' => sub {
    my $result = $manager->validate({
        category => 1,
        id       => 1,
    });
    is $result->valid, 'entry';
};

subtest 'fail category (entry)' => sub {
    my $result = $manager->validate({
        category => 'candy',
        id       => 1,
    });
    ok not $result->valid;
    cmp_deeply $result->error('entry'), superhashof( { name => 'category', type => 'InvalidValue' } );
};

subtest 'fail category (collection)' => sub {
    my $result = $manager->validate({
        category => 'candy',
        id       => [1],
    });
    ok not $result->valid;
    cmp_deeply $result->error('collection'), superhashof( { name => 'category', type => 'InvalidValue' } );
};

done_testing;
