use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::chkfacl',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/chkfacl.pm',
    requires          => {
        'perl'             => 5.008,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    add_to_cleanup     => [ 'App-chkfacl-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/App-chkfacl.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::chkfacl',
        },
    },
);

$builder->create_build_script();
