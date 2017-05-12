use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bundle::Unicheck',
    license             => 'artistic_2',
    dist_author         => q{Matthias Krull <m.krull@uninets.eu>},
    dist_version_from   => 'lib/Bundle/Unicheck.pm',

    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
    },
    add_to_cleanup     => [ 'Bundle-Unicheck-* Build _build MYMETA.*' ],
    create_makefile_pl => 'traditional',

    meta_add => {
        no_index => { directory => ['t'] },
        release_status      => 'unstable',
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/uninets/Bundle-Unicheck',
        }
    }
);

$builder->create_build_script();
