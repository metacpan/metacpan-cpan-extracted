use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer::Plugin::Tail',
    AUTHOR           => q{Hagop "Jack" Bilemjian <jck000@gmail.com>},
    VERSION_FROM     => 'lib/Dancer/Plugin/Tail.pm',
    ABSTRACT_FROM    => 'lib/Dancer/Plugin/Tail.pm',
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
        'String::Random'  => 0.26,
        'File::Temp'      => 0.22,
        'Dancer'          => 1.3099,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer-Plugin-Tail-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/jck000/Dancer-Plugin-Tail',
            bugtracker => 'https://github.com/jck000/Dancer-Plugin-Tail/issues',
            homepage   => 'https://github.com/jck000/Dancer-Plugin-Tail/',
        },
    },
);

