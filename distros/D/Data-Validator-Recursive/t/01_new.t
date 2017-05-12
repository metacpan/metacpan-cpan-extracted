use strict;
use warnings;
use Test::More;
use Data::Validator::Recursive;

subtest 'no args' => sub {
    eval { Data::Validator::Recursive->new };
    like $@, qr/Usage: /;
};

subtest 'simple' => sub {
    my $rule = new_ok 'Data::Validator::Recursive', [
        foo => 'Str',
    ];

    isa_ok $rule->{validator}, 'Data::Validator';
    is scalar @{ $rule->{nested_validators} }, 0;
    is $rule->{error}, undef;
};

subtest 'nested' => sub {
    my $rule = new_ok 'Data::Validator::Recursive', [
        foo => 'Str',
        bar => {
            isa  => 'Int',
            rule => [
                baz => 'Str',
            ],
        },
    ];

    isa_ok $rule->{validator}, 'Data::Validator';

    my $nested = $rule->{nested_validators};
    is @$nested, 1;
    is $nested->[0]->{name}, 'bar';
    isa_ok $nested->[0]->{validator}, 'Data::Validator::Recursive';
    is $rule->{error}, undef;
};

subtest 'nested (hash)' => sub {
    my $rule = new_ok 'Data::Validator::Recursive', [
        foo => 'Str',
        bar => {
            isa  => 'Int',
            rule => {
                baz => 'Str',
            },
        },
    ];

    isa_ok $rule->{validator}, 'Data::Validator';

    my $nested = $rule->{nested_validators};
    is @$nested, 1;
    is $nested->[0]->{name}, 'bar';
    isa_ok $nested->[0]->{validator}, 'Data::Validator::Recursive';
    is $rule->{error}, undef;
};

subtest 'invalid nested rule' => sub {
    eval {
        Data::Validator::Recursive->new(
            foo => 'Str',
            bar => {
                isa  => 'Int',
                rule => 'invalid',
            },
        );
    };
    like $@, qr/bar\.rule must be ARRAY or HASH/;
};

done_testing;
