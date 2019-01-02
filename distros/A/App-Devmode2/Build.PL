use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::Devmode2',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/Devmode2.pm',
    requires          => {
        'perl'        => 5.008,
        'Path::Tiny'  => 0,
        'YAML'        => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.98',
        'Test::Warnings' => '0.026',
    },
    recommends => {
        'Term::Title' => 0,
    },
    add_to_cleanup     => [ 'App-Devmode2-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/App-Devmode2.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::Devmode2',
        },
    },
);

$builder->create_build_script();
