use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %dependencies = (
    'Perlmazing' => 1,
);

my %params = (
    NAME             => 'Attribute::Handlers::Clean',
    AUTHOR           => q{Francisco Zarabozo <zarabozo@cpan.org>},
    VERSION_FROM     => 'lib/Attribute/Handlers/Clean.pm',
    ABSTRACT_FROM    => 'lib/Attribute/Handlers/Clean.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        %dependencies,
    },
    BUILD_REQUIRES	=> {
        %dependencies,
    },
    TEST_REQUIRES	=> {
        %dependencies,
    },
    PREREQ_PM		=> {
        %dependencies,
    },
    dist			=> {
        COMPRESS	=> 'gzip -9f',
        SUFFIX		=> 'gz',
    },
    clean			=> {
        FILES => 'Attribute-Handlers-Clean-*',
    },
    META_MERGE		=> {
        no_index	=> {
            directory => [
                "demo",
            ],
        },
    },
);

delete $params{TEST_REQUIRES} unless ExtUtils::MakeMaker->VERSION >= 6.64;

WriteMakefile(%params);
