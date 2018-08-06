use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::filewatch',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/filewatch.pm',
    requires          => {
        'perl'                 => 5.010,
        'AnyEvent'             => 0,
        'AnyEvent::Loop'       => 0,
        'File::TypeCategories' => 0,
        'Linux::Inotify2'      => 0,
        'Path::Tiny'           => 0,
        'version'              => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    add_to_cleanup     => [ 'App-filewatch-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/App-filewatch.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::filewatch',
        },
    },
);

$builder->create_build_script();
