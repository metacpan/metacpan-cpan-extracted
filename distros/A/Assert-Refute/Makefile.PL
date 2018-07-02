use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Assert::Refute',
    AUTHOR           => q{Konstantin S. Uvarin <khedin@gmail.com>},
    VERSION_FROM     => 'lib/Assert/Refute.pm',
    ABSTRACT_FROM    => 'lib/Assert/Refute.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006002',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More'          => 0.87, # done_testing + subtest
    },
    PREREQ_PM => {
        'Scalar::Util'        => 1.14, # set_prototype
        'parent'              => 0,
        'Data::Dumper'        => 2,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/dallaylaen/assert-refute-perl/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/dallaylaen/assert-refute-perl.git',
                web => 'https://github.com/dallaylaen/assert-refute-perl',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Assert-Refute-*' },
);
