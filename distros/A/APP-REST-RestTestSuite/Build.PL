use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'APP::REST::RestTestSuite',
    license             => 'artistic_2',
    dist_author         => q{Mithun Radhakrishnan <rkmithun@cpan.org>},
    dist_version_from   => 'lib/APP/REST/RestTestSuite.pm',
    dist_abstract       => 'rest-client => Test automation tool for restful web services',
    release_status      => 'stable',
    script_files      => [
        'script/rest-client', 
    ],
    meta_merge        => {
        resources => {
            repository => 'https://github.com/rkmithun/APP-REST-RestTestSuite'
        }
    },
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires           => {
        'LWP::Parallel::UserAgent' => 0,
        'LWP::UserAgent'           => 0,
        'HTTP::Request'            => 0,
        'File::Path'               => 0,
        'File::Basename'           => 0,
        'Time::HiRes'              => 0,
        'Getopt::Long'             => 0,
    },
    add_to_cleanup     => [ 'APP-REST-RestTestSuite-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
