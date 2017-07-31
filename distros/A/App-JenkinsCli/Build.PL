use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::JenkinsCli',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/JenkinsCli.pm',
    requires          => {
        'perl'           => '5.010',
        'DateTime'       => 0,
        'File::ShareDir' => 0,
        'Getopt::Alt'    => '0.4.4',
        'Jenkins::API'   => '0.11',
        'Moo'            => '2.0',
        'Path::Tiny'     => '0.076',
        'XML::LibXML'    => '2.0',
        'XML::LibXSLT'   => '1.90',
        'XML::Simple'    => '2.22',
    },
    build_requires => {
        'Test::More'     => 0,
        'Test::Warnings' => 0,
    },
    share_dir => {
        dist => [
            'xslt',
        ],
    },
    add_to_cleanup     => [ 'App-JenkinsCli-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/App-jenkins-cli.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::JenkinsCli',
        },
    },
);

$builder->create_build_script();
