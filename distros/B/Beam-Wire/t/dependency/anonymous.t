
use Test::More;
use Test::Exception;
use Test::Lib;
use Test::Deep;
use Beam::Wire;

subtest 'anonymous reference' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::RefTest',
                args  => {
                    got_ref => {
                        '$class' => 'My::ArgsTest',
                        '$args' => {
                            foo => 'Bar',
                        },
                    },
                },
            },
        },
    );

    my $svc;
    lives_ok { $svc = $wire->get( 'foo' ) };
    isa_ok $svc, 'My::RefTest';
    isa_ok $svc->got_ref, 'My::ArgsTest';
    cmp_deeply $svc->got_ref->got_args_hash, { foo => 'Bar' };
};

subtest 'anonymous extends' => sub {
    my $wire = Beam::Wire->new(
        config => {
            bar => {
                class => 'My::ArgsTest',
                args => {
                    foo => 'HIDDEN',
                },
            },
            foo => {
                class => 'My::RefTest',
                args  => {
                    got_ref => {
                        '$extends' => 'bar',
                        '$args' => {
                            foo => 'Bar',
                        },
                    },
                },
            },
        },
    );

    my $svc;
    lives_ok { $svc = $wire->get( 'foo' ) };
    isa_ok $svc, 'My::RefTest';
    isa_ok $svc->got_ref, 'My::ArgsTest';
    cmp_deeply $svc->got_ref->got_args_hash, { foo => 'Bar' };
};


done_testing;
