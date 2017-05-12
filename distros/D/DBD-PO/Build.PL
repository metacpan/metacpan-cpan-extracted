use strict;
use warnings;

use Module::Build;

my $is_ppm
    = (
        # install using ppm
        ! $ENV{AUTHOR_DIST}
        && eval 'require ActivePerl::PPM::Package'
    )
    || (
        # build ppm and ppd
        $ENV{AUTHOR_DIST}
        && $ENV{AUTHOR_DIST} eq 'ppm'
    );

Module::Build->new(
    module_name       => 'DBD::PO',
    license           => 'perl',
    dist_abstract     => 'DBD::PO - DBI driver for PO files',
    dist_author       => 'Steffen Winkler <steffenw at cpan.org>',
    dist_version_from => 'lib/DBD/PO.pm',
    requires          => {
        perl               => '5.006',
        version            => 0,
        parent             => 0,
        DBI                => 0, # for DBD::File
        'Set::Scalar'      => '1.25',
        'SQL::Statement'   => 0, # for SQL::Parser
        'Params::Validate' => 0,
        $is_ppm
        ? ()
        : (
            Carp     => 0, # perl dist
            English  => 0, # perl dist
            Socket   => 0, # perl dist
            Storable => 0, # perl dist
        )
    },
    build_requires => {
        'Test::NoWarnings'  => 0,
        'Test::Exception'   => 0,
        'Test::Differences' => 0,
        Encode              => 0,
        'File::Find'        => 0,
        $is_ppm
        ? (
            'Test::Simple'      => 0,
        )
        : (
            'Test::More' => 0, # dist Test-Simple
            Cwd          => 0, # perl dist
            charnames    => 0, # perl dist
        )
    },
    recommends => {
        'DBD::File'           => 0,
        'SQL::Parser'         => 0,
        # build
        'Test::Pod'           => '1.14',
        'Test::Pod::Coverage' => '1.04',
    },
    create_makefile_pl   => 'traditional',
    recursive_test_files => 1,
    add_to_cleanup       => [ qw(
        META.yml *.bak *.gz Makefile.PL *.po *.txt
    ) ],
)->create_build_script();