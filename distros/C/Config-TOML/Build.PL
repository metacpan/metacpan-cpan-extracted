use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Config::TOML',
    license             => 'lgpl',
    dist_author         => q{Alex Kalderimis <alex.kalderimis@gmail.com>},
    dist_version_from   => 'lib/Config/TOML.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    requires => {
        'DateTime' => 0,
        'IO::All' => 0,
        'List::Util' => 0
    },
    add_to_cleanup     => [ 'Config-TOML-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
