use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::watchdo',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/watchdo.pm',
    requires          => {
        'perl'                      => '5.010',
        'AnyEvent'                  => '7.0',
        'AnyEvent::Filesys::Notify' => '1.21',
        'AnyEvent::Loop'            => 0,
        'List::MoreUtils'           => '0.4',
        'Moo'                       => '2.0',
        'Path::Tiny'                => '0.068',
        'VCS::Which'                => '0.6.1',
        'version'                   => '0.9912',
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    add_to_cleanup     => [ 'App-watchdo-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/App-watch-do.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::watchdo',
        },
    },
);

$builder->create_build_script();
