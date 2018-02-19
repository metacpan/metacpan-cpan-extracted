use 5.008009;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my $module_name = 'DBIx::BatchChunker';

my $dist_name = $module_name;
$dist_name =~ s/::/-/g;

my $module_file = $module_name;
$module_file =~ s{::}{/}g;
$module_file = "lib/$module_file.pm";

# Standard boilerplate WriteMakefile args
my %WriteMakefileArgs = (
    NAME          => $module_name,
    DISTNAME      => $dist_name,
    VERSION_FROM  => $module_file,
    ABSTRACT_FROM => $module_file,
    AUTHOR        => 'Grant Street Group <developers@grantstreet.com>',

    # The recommended choice by Larry Wall and crew
    LICENSE       => 'artistic_2',

    # Use a sane version of EUMM that supports *_REQUIRES
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.64' },

    META_MERGE => {
        # Tells EUMM these properties are for CPAN::Meta::Spec v2
        'meta-spec' => { version => 2 },

        # GitHub links
        resources => {
            bugtracker => {
                web => "https://github.com/GrantStreetGroup/$dist_name/issues",
            },
            homepage   => "https://github.com/GrantStreetGroup/$dist_name",
            repository => {
                type => 'git',
                url  => "https://github.com/GrantStreetGroup/$dist_name.git",
                web  => "https://github.com/GrantStreetGroup/$dist_name",
            }
        },
        x_authority => 'cpan:GSG',
    },

    clean => { FILES => "$dist_name-*" },
    test  => { TESTS => 't/*.t' },
);

# Per-dist customizations
%WriteMakefileArgs = (
    %WriteMakefileArgs,
    PREREQ_PM     => {
        # Start from "scan-perl-prereqs --pretty lib"

        'Moo'                    => '2.00',  # sane minimum baseline
        'CLDR::Number'           => 0,
        'Types::Standard'        => '1.00',  # sane minimum baseline
        'Types::Common::Numeric' => 0,
        'Type::Utils'            => 0,
        'Data::Float'            => 0,
        'List::Util'             => '1.33',  # has any/all/etc.
        'Scalar::Util'           => 0,
        'Term::ProgressBar'      => '2.14',  # with silent option
        'namespace::clean'       => 0,

        # not strictly required, but useless without it
        'DBI' => 0,
    },
    TEST_REQUIRES => {
        # Start from "scan-perl-prereqs --pretty t"

        'Test2::Bundle::More'     => 0,
        'Test2::Tools::Compare'   => 0,
        'Test2::Tools::Exception' => 0,
        'Test2::Tools::Explain'   => 0,
        'Scalar::Util'            => 0,

        'DBIx::Class' => 0,
        'Path::Class' => 0,
    },
);

# Don't index examples/*
$WriteMakefileArgs{META_MERGE}{no_index} = { directory => [qw< examples >] };

# Other prereqs not in *_REQUIRES
$WriteMakefileArgs{META_MERGE}{prereqs} = {
    runtime => {
        # Even though we require it in the tests, this is still optional for the module
        suggests => {
            'DBIx::Class' => 0,
        },
    },
};

WriteMakefile(%WriteMakefileArgs);
