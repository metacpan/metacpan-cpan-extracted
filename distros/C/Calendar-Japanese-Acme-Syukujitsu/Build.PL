use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Calendar::Japanese::Acme::Syukujitsu',
    license             => 'artistic_2',
    dist_author         => q{Nao Muto <n@o625.com>},
    dist_version_from   => 'lib/Calendar/Japanese/Acme/Syukujitsu.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp' => 1.36,
        'Class::Accessor::Lite' => 0.08,
        'Encode' => 2.92,
        'File::Slurp' => 9999.19,
        'Furl' => 3.11,
        'List::Util' => 1.48,
        'Smart::Args' => 0.14,
    },
    add_to_cleanup     => [ 'Calendar-Japanese-Acme-Syukujitsu-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
