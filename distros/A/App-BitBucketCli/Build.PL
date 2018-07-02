use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::BitBucketCli',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/BitBucketCli.pm',
    requires          => {
        'perl'              => '5.006',
        'Getopt::Alt'       => '0.4.5',
        'Module::Pluggable' => '5.0',
        'Moo'               => '2.0',
        'Path::Tiny'        => '0.076',
        'Scalar::Util'      => 0,
        'JSON::XS'          => 0,
        'WWW::Mechanize'    => 0,
        'YAML::Syck'        => 0,
    },
    build_requires => {
        'Module::Build'  => '0.422',
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    add_to_cleanup     => [ 'App-BitBucket-cli-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/App-bitbucket-cli.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::BitBucketCli',
        },
    },
);

$builder->create_build_script();
