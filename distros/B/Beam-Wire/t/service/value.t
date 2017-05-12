
use Test::More;
use Test::Exception;
use Test::Lib;
use Scalar::Util qw( refaddr );
use Beam::Wire;

subtest 'value service: simple scalar' => sub {
    my $wire = Beam::Wire->new(
        config => {
            greeting => {
                value => 'Hello, World'
            }
        },
    );

    my $greeting;
    lives_ok { $greeting = $wire->get( 'greeting' ) };
    ok !ref $greeting, 'got a simple scalar';
    is $greeting, 'Hello, World';
};

subtest 'value service (raw): array ref' => sub {
    my $wire = Beam::Wire->new(
        config => {
            greeting => [ 'Hello, World' ],
        },
    );

    my $greeting;
    lives_ok { $greeting = $wire->get( 'greeting' ) };
    is ref $greeting, 'ARRAY', 'got an array ref';
    is scalar @$greeting, 1, 'arrayref has 1 element';
    is $greeting->[0], 'Hello, World';

    subtest 'with $ref' => sub {
        my $wire = Beam::Wire->new(
            config => {
                greeting => [ 'Hello, World', { '$ref' => 'other' } ],
                other => 'Hello, Others!',
            },
        );

        my $greeting;
        lives_ok { $greeting = $wire->get( 'greeting' ) };
        is ref $greeting, 'ARRAY', 'got an array ref';
        is scalar @$greeting, 2, 'arrayref has 1 element';
        is $greeting->[0], 'Hello, World';
        is $greeting->[1], 'Hello, Others!';
    };
};

subtest 'value service (raw): hash ref' => sub {
    my $wire = Beam::Wire->new(
        config => {
            greeting => {
                hello => 'Hello',
                who => 'World',
            },
        },
    );

    my $greeting;
    lives_ok { $greeting = $wire->get( 'greeting' ) };
    is ref $greeting, 'HASH', 'got a hash ref';
    is $greeting->{hello}, 'Hello';
    is $greeting->{who}, 'World';

    subtest 'with $ref' => sub {
        my $wire = Beam::Wire->new(
            config => {
                greeting => {
                    hello => 'Hello',
                    who => { '$ref' => 'others' },
                },
                others => 'Others',
            },
        );

        my $greeting;
        lives_ok { $greeting = $wire->get( 'greeting' ) };
        is ref $greeting, 'HASH', 'got a hash ref';
        is $greeting->{hello}, 'Hello';
        is $greeting->{who}, 'Others';
    };
};

subtest 'value service (raw): scalar' => sub {
    my $wire = Beam::Wire->new(
        config => {
            greeting => 'Hello, World',
        },
    );

    my $greeting;
    lives_ok { $greeting = $wire->get( 'greeting' ) };
    ok !ref $greeting, 'got a simple scalar';
    is $greeting, 'Hello, World';
};

done_testing;
