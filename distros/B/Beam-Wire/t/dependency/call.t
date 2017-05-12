
use Test::More;
use Test::Exception;
use Test::Lib;
use Test::Deep;
use Beam::Wire;

subtest 'method with no arguments' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::RefTest',
                args  => {
                    got_ref => {
                        '$ref' => 'greeting',
                        '$call' => 'got_args_hash',
                    },
                },
            },
            greeting => {
                class => 'My::ArgsTest',
                args => {
                    hello => "Hello",
                    default => 'World',
                },
            },
        },
    );
    my $svc;
    lives_ok { $svc = $wire->get( 'foo' ) };
    isa_ok $svc, 'My::RefTest';
    cmp_deeply $svc->got_ref, { hello => 'Hello', default => 'World' }
        or diag explain $svc->got_ref;
};

subtest 'method with one argument' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::RefTest',
                args => {
                    got_ref => {
                        '$ref' => 'greeting',
                        '$call' => {
                            '$method' => 'got_args_hash',
                            '$args' => 'hello',
                        },
                    },
                },
            },
            greeting => {
                class => 'My::ArgsTest',
                args => {
                    hello => "Hello",
                    default => 'World',
                },
            },
        },
    );
    my $svc;
    lives_ok { $svc = $wire->get( 'foo' ) };
    isa_ok $svc, 'My::RefTest';
    cmp_deeply $svc->got_ref, [ 'Hello' ] or diag explain $svc->got_ref;
};

subtest 'method with arrayref of arguments' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::RefTest',
                args => {
                    got_ref => {
                        '$ref' => 'greeting',
                        '$call' => {
                            '$method' => 'got_args_hash',
                            '$args' => [ 'default', 'hello' ],
                        },
                    },
                },
            },
            greeting => {
                class => 'My::ArgsTest',
                args => {
                    hello => "Hello",
                    default => 'World',
                },
            },
        },
    );
    my $svc;
    lives_ok { $svc = $wire->get( 'foo' ) };
    isa_ok $svc, 'My::RefTest';
    cmp_deeply $svc->got_ref, [ 'World', 'Hello' ] or diag explain $svc->got_ref;
};

done_testing;
