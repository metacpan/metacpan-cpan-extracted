use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer::Logger::Hourlyfile',
    AUTHOR           => q{Hagop "Jack" Bilemjian <jck000@gmail.com>},
    VERSION_FROM     => 'lib/Dancer/Logger/Hourlyfile.pm',
    ABSTRACT_FROM    => 'lib/Dancer/Logger/Hourlyfile.pm',
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
        'File::Temp' => 0.22,
        'Dancer'     => 1.3099,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer-Logger-Hourlyfile-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/jck000/Dancer-Logger-Hourlyfile',
            bugtracker => 'https://github.com/jck000/Dancer-Logger-Hourlyfile/issues',
            homepage   => 'https://github.com/jck000/Dancer-Logger-Hourlyfile/',
        },
    },
);






