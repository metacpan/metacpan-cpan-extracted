use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $build = Module::Build->new(
    module_name         => 'Algorithm::Damm',
    license             => 'perl',
    dist_author         => q(Brian T. Wightman <MidLifeXis@wightmanfam.org>),
    dist_version_from   => 'lib/Algorithm/Damm.pm',
    configure_requires  => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => '5.6.0',
    },
    add_to_cleanup      => [ 'Algorithm-Damm-*' ],
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
    resources           => {
        repository => {
            url  => 'git://github.com/MidLifeXis/perl-algorithm-damm',
            web  => 'https://github.com/MidLifeXis/perl-algorithm-damm',
            type => 'git',
        },
    },
    );

$build->create_build_script;
