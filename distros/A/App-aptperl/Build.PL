use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::aptperl',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/aptperl.pm',
    requires          => {
        'perl'                   => 5.008,
        'CHI'                    => 0,
        'File::chdir'            => 0,
        'HTTP::Tiny::Mech'       => 0,
        'MetaCPAN::API'          => 0,
        'Module::CoreList'       => 0,
        'WWW::Mechanize::Cached' => 0,
        'YAML::Syck'             => 0,
        'version'                => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    add_to_cleanup     => [ 'App-apt-perl-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/App-apt-perl.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::aptperl',
        },
    },
);

$builder->create_build_script();
