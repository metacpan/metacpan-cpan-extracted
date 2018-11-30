use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::diffdir',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/diffdir.pm',
    requires          => {
        'perl'       => '5.010',
        'Moo'        => '2.000000',
        'Path::Tiny' => 0,
        'Text::Diff' => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    add_to_cleanup     => [ 'App-diffdir-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/App-diffdir.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::diffdir',
        },
    },
);

$builder->create_build_script();
