
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Lib;
use Beam::Wire;
use Path::Tiny qw( path tempdir cwd );
use FindBin qw( $Bin );
my $SHARE_DIR = path( $Bin, '..', 'share' );

my $EXPECT = {
    foo => 'bar',
    baz => [qw( 1 2 3 )],
    obj => {
        # References do not get resolved by $config
        '$class' => 'Beam::Wire',
        '$args' => {
            services => {
                foo => 'bar',
            },
        },
    },
};

subtest 'anonymous configs' => sub {

    my $wire = Beam::Wire->new(
        config => {
            foo => {
                class => 'My::ArgsTest',
                args  => {
                    foo => {
                        '$config' => $SHARE_DIR->child( config => 'config.yml' )->stringify,
                    },
                },
            },
        },
    );

    my $svc;
    lives_ok { $svc = $wire->get( 'foo' ) };
    isa_ok $svc, 'My::ArgsTest';
    cmp_deeply $svc->got_args_hash, { foo => $EXPECT };

    subtest 'use a config as all the arguments' => sub {
        my $wire = Beam::Wire->new(
            config => {
                foo => {
                    class => 'My::ArgsTest',
                    args  => {
                        '$config' => $SHARE_DIR->child( config => 'config.yml' )->stringify,
                    },
                },
            },
        );

        my $svc;
        lives_ok { $svc = $wire->get( 'foo' ) };
        isa_ok $svc, 'My::ArgsTest';
        cmp_deeply $svc->got_args_hash, $EXPECT;

    };
};

subtest 'config references' => sub {

    subtest 'ref a config' => sub {
        my $wire = Beam::Wire->new(
            config => {
                yaml => {
                    config => $SHARE_DIR->child( config => 'config.yml' )->stringify,
                },
                foo => {
                    class => 'My::ArgsTest',
                    args  => {
                        foo => {
                            '$ref' => 'yaml',
                        },
                    },
                },
            },
        );

        my $svc;
        lives_ok { $svc = $wire->get( 'foo' ) };
        isa_ok $svc, 'My::ArgsTest';
        cmp_deeply $svc->got_args_hash, { foo => $EXPECT };
    };

    subtest 'ref a path in a config' => sub {
        my $wire = Beam::Wire->new(
            config => {
                yaml => {
                    config => $SHARE_DIR->child( config => 'config.yml' )->stringify,
                },
                foo => {
                    class => 'My::ArgsTest',
                    args  => {
                        foo => {
                            '$ref' => 'yaml',
                            '$path' => '/foo',
                        },
                    },
                },
            },
        );

        my $svc;
        lives_ok { $svc = $wire->get( 'foo' ) };
        isa_ok $svc, 'My::ArgsTest';
        cmp_deeply $svc->got_args_hash, { foo => $EXPECT->{foo} }
            or diag explain $svc->got_args_hash;
    };
};

done_testing;
