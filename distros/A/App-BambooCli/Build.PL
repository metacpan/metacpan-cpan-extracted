use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App-BambooCli',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/BambooCli.pm',
    requires          => {
        'perl'              => 5.008,
        'Getopt::Alt'       => 0,
        'List::Util'        => 0,
        'Module::Pluggable' => '5.2',
        'Moo'               => 0,
        'Net::Bamboo'       => 0,
        'Path::Tiny'        => 0,
        'Scalar::Util'      => 0,
        'YAML::Syck'        => '1.31',
        'version'           => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => 0,
        'Test::Warnings' => 0,
    },
    add_to_cleanup     => [ 'App-BambooCli-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/App-Bamboo-Cli.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Bamboo-Cli',
        },
    },
);

$builder->create_build_script();
