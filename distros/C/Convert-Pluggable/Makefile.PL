use strict;
use warnings FATAL => 'all';

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Convert::Pluggable',
    AUTHOR           => q{bradley andersen <bradley@pvnp.us>},
    VERSION_FROM     => 'lib/Convert/Pluggable.pm',
    ABSTRACT_FROM    => 'lib/Convert/Pluggable.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Math::Round' => 0,
        'Data::Dump' => 0,
        'File::Basename' => 0,
        'File::Slurp' => 0,
        'Switch' => 0,
    },
    PREREQ_PM => {
        'Data::Float' => 0,
        'Exporter' => 0,
        'JSON' => 0,
        'Scalar::Util' => 0,
        'Moo' => 0,
        'Math::Round' => 0,
        'File::Basename' => 0,
        'File::Slurp' => 0,
        'Switch' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Convert-Pluggable-*' },
);
