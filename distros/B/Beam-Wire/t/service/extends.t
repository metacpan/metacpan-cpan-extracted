
use Test::More;
use Test::Exception;
use Test::Deep;
use Test::Lib;
use Beam::Wire;

subtest 'scalar args' => sub {
    my $wire = Beam::Wire->new(
        config => {
            base_scalar => {
                class => 'My::ArgsTest',
                args  => 'Hello, World',
            },
            scalar_no_change => {
                extends => 'base_scalar',
            },
            scalar => {
                extends => 'base_scalar',
                args => 'Goodbye, World',
            },

            base_method => {
                extends => 'base_scalar',
                class => 'My::MethodTest',
                method => 'dies',
            },

            scalar_nested_extends => {
                extends => 'base_method',
                method => 'new',
            },
        },
    );
    my $expect_base_scalar = $wire->get_config( 'base_scalar' );
    my $expect_base_method = $wire->get_config( 'base_method' );

    subtest 'extends scalar args, new args' => sub {
        my $svc;
        lives_ok { $svc = $wire->get( 'scalar' ) };
        isa_ok $svc, 'My::ArgsTest';
        cmp_deeply $svc->got_args, [ 'Goodbye, World' ];
        cmp_deeply $wire->get_config( 'base_scalar' ), $expect_base_scalar,
            'extends does not modify original config';
    };

    subtest 'extends scalar args, no changes' => sub {
        my $svc;
        lives_ok { $svc = $wire->get( 'scalar_no_change' ) };
        isa_ok $svc, 'My::ArgsTest';
        cmp_deeply $svc->got_args, [ 'Hello, World' ];
        cmp_deeply $wire->get_config( 'base_scalar' ), $expect_base_scalar,
            'extends does not modify original config';
    };

    subtest 'extends scalar args, new method, extends another extends' => sub {
        my $svc;
        dies_ok { $svc = $wire->get( 'base_method' ) };
        lives_ok { $svc = $wire->get( 'scalar_nested_extends' ) };
        isa_ok $svc, 'My::MethodTest';
        cmp_deeply $svc->got_args, [ 'Hello, World' ];
        cmp_deeply $wire->get_config( 'base_scalar' ), $expect_base_scalar,
            'extends does not modify original config';
        cmp_deeply $wire->get_config( 'base_method' ), $expect_base_method,
            'extends does not modify original config';
    };
};

subtest 'array args' => sub {
    my $wire = Beam::Wire->new(
        config => {
            base_array => {
                class => 'My::ArgsTest',
                args => [ [ 'Hello', 'World' ] ],
            },
            array => {
                extends => 'base_array',
                args => [ [ 'Goodbye', 'World' ] ],
            },
            replace_with_hash => {
                extends => 'base_array',
                args => {
                    foo => 'Hello',
                },
            },
        },
    );

    my $expect_base_array = $wire->get_config( 'base_array' );

    subtest 'extends array args, new args' => sub {
        my $svc;
        lives_ok { $svc = $wire->get( 'array' ) };
        isa_ok $svc, 'My::ArgsTest';
        cmp_deeply $svc->got_args, [ [ 'Goodbye', 'World' ] ];
        cmp_deeply $wire->get_config( 'base_array' ), $expect_base_array,
            'extends does not modify original config';
    };

    subtest 'extends array args, change to hash args' => sub {
        my $svc;
        lives_ok { $svc = $wire->get( 'replace_with_hash' ) };
        isa_ok $svc, 'My::ArgsTest';
        cmp_deeply $svc->got_args, [ foo => 'Hello'];
        cmp_deeply $wire->get_config( 'base_array' ), $expect_base_array,
            'extends does not modify original config';
    };
};

subtest 'hash args' => sub {
    my $wire = Beam::Wire->new(
        config => {
            base_hash => {
                class => 'My::ArgsTest',
                args => {
                    hello => 'Hello',
                    who => 'World',
                },
            },
            hash => {
                extends => 'base_hash',
                args => {
                    who => 'Everyone',
                },
            },
        },
    );

    my $expect_base_hash = $wire->get_config( 'base_hash' );

    subtest 'extends hash args, new args' => sub {
        my $svc;
        lives_ok { $svc = $wire->get( 'hash' ) };
        isa_ok $svc, 'My::ArgsTest';
        cmp_deeply $svc->got_args_hash, { hello => 'Hello', who => 'Everyone' };
        cmp_deeply $wire->get_config( 'base_hash' ), $expect_base_hash,
            'extends does not modify original config';
    };

};

subtest 'extends (raw): hash' => sub {
    my $wire = Beam::Wire->new(
        config => {
            base_hash => {
                '$class' => 'My::ArgsTest',
                hello => 'Hello',
                who => 'World',
            },
            hash => {
                '$extends' => 'base_hash',
                who => 'Everyone',
            },
        },
    );

    my $expect_base_hash = $wire->get_config( 'base_hash' );

    my $svc;
    lives_ok { $svc = $wire->get( 'hash' ) };
    isa_ok $svc, 'My::ArgsTest';
    cmp_deeply $svc->got_args_hash, { hello => 'Hello', who => 'Everyone' };
    cmp_deeply $wire->get_config( 'base_hash' ), $expect_base_hash,
        'extends does not modify original config';
};

subtest 'nested data structures' => sub {
    # These pathological cases are for later if we decide to
    # do this kind of merging differently

    my $wire = Beam::Wire->new(
        config => {
            base_arraynest => {
                class => 'My::ArgsTest',
                args => [ [
                    'Hello',
                    [
                        { English => 'World' },
                        { French => 'Tout Le Monde' },
                    ],
                ] ],
            },
            base_hashnest => {
                class => 'My::ArgsTest',
                args => {
                    hello => {
                        English => 'Hello',
                        French => 'Bonjour',
                    },
                    who => [
                        { English => 'World' },
                        { French => 'Tout Le Monde' },
                    ],
                },
            },
            arraynest => {
                extends => 'base_arraynest',
                args => [ [
                    'Goodbye',
                    [
                        { Spanish => 'Mundo' },
                    ],
                ] ],
            },
            hashnest => {
                extends => 'base_hashnest',
                args => {
                    who => [
                        { Spanish => 'Mundo' },
                    ],
                },
            },
        },
    );

    subtest 'extends arraynest, new args' => sub {
        my $svc;
        lives_ok { $svc = $wire->get( 'arraynest' ) };
        isa_ok $svc, 'My::ArgsTest';
        cmp_deeply $svc->got_args, [ [ 'Goodbye', [ { Spanish => 'Mundo' } ] ] ];
    };
    subtest 'extends hashnest, new args' => sub {
        my $svc;
        lives_ok { $svc = $wire->get( 'hashnest' ) };
        isa_ok $svc, 'My::ArgsTest';
        cmp_deeply $svc->got_args_hash, {
            hello => { English => 'Hello', French => 'Bonjour' },
            who => [ { Spanish => 'Mundo' } ],
        };
    };
};

subtest 'extended service does not exist' => sub {
    my $wire;
    lives_ok {
        $wire = Beam::Wire->new(
            config => {
                hash => {
                    extends => 'base_hash',
                    args => {
                        who => 'Everyone',
                    },
                },
            },
        );
    } 'creating a bad wire is fine';
    dies_ok { $wire->get( 'hash' ) } 'getting a bad service is not';
};

done_testing;
