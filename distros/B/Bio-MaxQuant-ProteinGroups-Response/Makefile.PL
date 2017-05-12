use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Bio::MaxQuant::ProteinGroups::Response',
    AUTHOR           => q{Jimi <j@0na.me>},
    VERSION_FROM     => 'lib/Bio/MaxQuant/ProteinGroups/Response.pm',
    ABSTRACT_FROM    => 'lib/Bio/MaxQuant/ProteinGroups/Response.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
        'Statistics::Reproducibility' => 0.06,
        'Text::CSV' => 1.32,
        'IO::File' => 1.14,
        'File::Path' => 2.09,
        'Math::SigFigs' => 1.09,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bio-MaxQuant-ProteinGroups-Response-*' },
);
