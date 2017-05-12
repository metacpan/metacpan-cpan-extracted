#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More;
use Test::Deep;

use Data::Validator::MultiManager;

my $manager = Data::Validator::MultiManager->new('Data::Validator::Recursive');
$manager->add(
    nest => {
        human => {
            rule => [
                name => { isa => 'Str' },
                age  => { isa => 'Int' },
            ]
        },
    },
    flat => {
        name => { isa => 'Str' },
        age  => { isa => 'Int' },
    },
);

subtest 'nest' => sub {
    my $result = $manager->validate({
        human => {
            name => 'hixi',
            age  => 24,
        },
    });
    is $result->valid, 'nest';
};

subtest 'flat' => sub {
    my $result = $manager->validate({
        name => 'hixi',
        age  => 24,
    });
    is $result->valid, 'flat';
};

subtest 'fail' => sub {
    my $result = $manager->validate({ id => 'aaa' });
    ok not $result->valid;
};

done_testing;
