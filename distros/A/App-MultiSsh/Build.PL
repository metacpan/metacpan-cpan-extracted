use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::MultiSsh',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/MultiSsh.pm',
    requires          => {
        'perl'                 => '5.010',
        'IPC::Open3::Callback' => 0,
        'Path::Tiny'           => 0,
        'YAML'                 => 0,
        'version'              => 0,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => 0,
    },
    add_to_cleanup     => [ 'App-MultiSsh-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/App-MultiSsh.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::MultiSsh',
        },
    },
);

$builder->create_build_script();
