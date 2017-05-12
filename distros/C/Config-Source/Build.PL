use 5.14.0;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Config::Source',
    license             => 'perl',
    dist_author         => q{Tarek Unger <taunger@cpan.org>},
    dist_version_from   => 'lib/Config/Source.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    requires => {
        'Data::Dumper' => 0,
        'Storable' => 0,
        'List::Util' => 1.35, 
    },
    add_to_cleanup     => [ 'Config-Source-*' ],
    create_makefile_pl => 'traditional',

    meta_merge     => {
        resources => {
            repository  => 'https://github.com/taunger/Config-Source'
        }
    },
);

$builder->create_build_script();
