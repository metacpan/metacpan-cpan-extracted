#!perl

####################
# LOAD MODULES
####################
use strict;
use warnings FATAL => 'all';
use Module::Build;

# Autoflush ON
local $| = 1;

####################
# INIT BUILDER
####################

my $builder = Module::Build->new(

    # Basic Info
    module_name => 'CASCM::CLI',
    license     => 'perl',
    dist_author => 'Mithun Ayachit <mithun@cpan.org>',

    # dist_abstract => '',

    # Directives
    create_packlist      => 1,
    create_license       => 1,
    create_makefile_pl   => 'traditional',
    recursive_test_files => 1,
    add_to_cleanup       => ['CASCM-CLI-*'],

    # Prereqs
    configure_requires => {

        # Version that ships with perl-5.10.1
        'Module::Build' => '0.340201',
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Deep' => 0,
        'Test::Pod'  => '1.00',
        'version'    => 0,
    },
    requires => {

        # Perl Version
        'perl' => '5.008001',

        # Dependencies
        'CASCM::Wrapper'              => '1.0.1',
        'Config::Tiny'                => 0,
        'File::HomeDir'               => 0,
        'File::Spec'                  => 0,
        'Getopt::Long'                => 0,
        'Getopt::Mini'                => 0,
        'Hash::Merge'                 => 0,
        'Log::Any::Adapter'           => 0,
        'Log::Any::Adapter::Callback' => 0,
        'Object::Tiny'                => 0,
    },

    # Recommendations
    recommends => {

    },

    # Meta
    meta_merge => {
        no_index => {
            directory => [ '.author', '.t', 'examples', ],
        },
        keywords  => [qw(cascm harvest cli hv)],
        resources => {
            bugtracker => 'https://github.com/mithun/perl-cascm-cli/issues',
            repository => 'git://github.com/mithun/perl-cascm-cli.git',
            homepage   => 'https://github.com/mithun/perl-cascm-cli',
        },
    },
);

####################
# CREATE BUILD SCRIPT
####################
$builder->create_build_script();
