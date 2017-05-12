use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Audio::Cuefile::Parser',
    AUTHOR              => 'Matt Koscica <matt.koscica@gmail.com>',
    VERSION_FROM        => 'lib/Audio/Cuefile/Parser.pm',
    ABSTRACT_FROM       => 'lib/Audio/Cuefile/Parser.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Audio-Cuefile-Parser-*' },
);
