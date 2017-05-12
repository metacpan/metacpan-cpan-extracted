
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Lib;
use Scalar::Util qw( refaddr );
use Beam::Wire;

subtest 'class args: hash' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::ArgsTest',
                args => {
                    foo => 'bar',
                },
            },
        },
    );

    my $foo;
    lives_ok { $foo = $wire->get( 'foo' ) };
    cmp_deeply $foo->got_args, [ foo => 'bar' ];

    subtest 'empty hash' => sub {
        my $wire = Beam::Wire->new(
            config => {
                foo => {
                    class => 'My::ArgsTest',
                    args => { },
                },
            },
        );

        my $foo;
        lives_ok { $foo = $wire->get( 'foo' ) };
        cmp_deeply $foo->got_args, [ ];
    };
};

subtest 'class args: array' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::ArgsTest',
                args => [
                    qw( foo bar )
                ],
            },
        },
    );

    my $foo;
    lives_ok { $foo = $wire->get( 'foo' ) };
    cmp_deeply $foo->got_args, [qw( foo bar )];
};

subtest 'class args: hashref' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::ArgsTest',
                args => [
                    { foo => 'bar' },
                ],
            },
        },
    );

    my $foo;
    lives_ok { $foo = $wire->get( 'foo' ) };
    cmp_deeply $foo->got_args, [{ foo => 'bar' }];

    subtest 'empty hashref' => sub {
        my $wire = Beam::Wire->new(
            config => {
                foo => {
                    class => 'My::ArgsTest',
                    args => [ { } ],
                },
            },
        );

        my $foo;
        lives_ok { $foo = $wire->get( 'foo' ) };
        cmp_deeply $foo->got_args, [ { } ];
    };
};

subtest 'class args: arrayref' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::ArgsTest',
                args => [
                    [qw( foo bar baz )],
                ],
            },
        },
    );

    my $foo;
    lives_ok { $foo = $wire->get( 'foo' ) };
    cmp_deeply $foo->got_args, [[qw( foo bar baz )]];
};

subtest 'class args: scalar' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::ArgsTest',
                args => [ 'foo' ],
            },
        },
    );

    my $foo;
    lives_ok { $foo = $wire->get( 'foo' ) };
    cmp_deeply $foo->got_args, [ 'foo' ];
};

subtest 'class args (raw): hashref' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                '$class' => 'My::ArgsTest',
                foo => 'bar',
            },
        },
    );

    my $foo;
    lives_ok { $foo = $wire->get( 'foo' ) };
    cmp_deeply $foo->got_args, [ foo => 'bar' ];
};

subtest 'class args (raw): with method' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                '$class' => 'My::ArgsTest',
                '$method' => 'new',
                foo => 'bar',
            },
        },
    );

    my $foo;
    lives_ok { $foo = $wire->get( 'foo' ) };
    cmp_deeply $foo->got_args, [ foo => 'bar' ];
};

done_testing;
