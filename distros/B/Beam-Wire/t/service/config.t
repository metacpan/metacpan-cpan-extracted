
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

subtest 'yaml config file' => sub {
    my $wire = Beam::Wire->new(
        config => {
            yaml => {
                config => $SHARE_DIR->child( 'config', 'config.yml' )->stringify,
            },
        },
    );

    my $svc;
    lives_ok { $svc = $wire->get( 'yaml' ) };
    cmp_deeply $svc, $EXPECT;

    subtest 'config is relative to container dir attribute' => sub {
        my $wire = Beam::Wire->new(
            file => $SHARE_DIR->child( 'with_config.yml' )->relative( cwd )->stringify,
        );

        my $svc;
        lives_ok { $svc = $wire->get( 'yaml' ) };
        cmp_deeply $svc, $EXPECT;
    };

    subtest 'config looks in multiple directories' => sub {
        my $wire = Beam::Wire->new(
            dir => [$SHARE_DIR->child('beam_path'), $SHARE_DIR],
            file => $SHARE_DIR->child( 'with_config.yml' )->relative( cwd )->stringify,
        );

        my $svc;
        lives_ok { $svc = $wire->get( 'yaml' ) };
        cmp_deeply $svc, { foo => 'OVERRIDDEN' };
    };

    subtest 'absolute path works' => sub {
        my $wire = Beam::Wire->new(
            file => $SHARE_DIR->child( 'with_config.yml' )->stringify,
        );

        my $svc;
        lives_ok { $svc = $wire->get( 'yaml' ) };
        cmp_deeply $svc, $EXPECT;
    };

    subtest 'config file missing returns empty' => sub {
        # This is not ideal, but it's the behavior we had before I added $default and so this is the behavior we'll have after... for now...
        my $wire = Beam::Wire->new(
            dir => [],
            config => {
              yaml => {
                '$config' => 'missing.yml',
              }
            }
        );
        my $svc;
        lives_ok { $svc = $wire->get( 'yaml' ) };
        cmp_deeply $svc, undef;
    };

    subtest 'config file missing uses $default' => sub {
        my $wire = Beam::Wire->new(
            dir => [],
            config => {
              yaml => {
                '$config' => 'missing.yml',
                '$default' => { foo => 'DEFAULT' },
              }
            }
        );

        my $svc;
        lives_ok { $svc = $wire->get( 'yaml' ) };
        cmp_deeply $svc, { foo => 'DEFAULT' };
    };

};

done_testing;
