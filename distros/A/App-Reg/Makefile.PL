use 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::Reg',
    AUTHOR           => 'Konrad Borowski <glitchmr@myopera.com>',
    VERSION_FROM     => 'lib/App/Reg.pm',
    ABSTRACT_FROM    => 'lib/App/Reg.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'File::Spec' => 0,
        'Capture::Tiny' => 0,
    },
    PREREQ_PM => {
        strict => 0,
        warnings => 0,
        Exporter => 0,
        re => 0,
        'Getopt::Long' => 0,
        'Pod::Usage' => 0,
        Encode => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-Reg-*' },
    EXE_FILES => ['bin/reg'],
);
