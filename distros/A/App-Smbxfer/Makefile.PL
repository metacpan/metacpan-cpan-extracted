use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::Smbxfer',
    AUTHOR              => 'Karl Erisman <karl.erisman@gmail.com>',
    VERSION_FROM        => 'lib/App/Smbxfer.pm',
    ABSTRACT_FROM       => 'lib/App/Smbxfer.pm',
    EXE_FILES           => [ qw( bin/smbxfer ) ],
    PL_FILES            => {},
    PREREQ_PM => {
        'Exporter' => 0,
        'Getopt::Long' => 0,
        'IO::Prompt' => 0,
        'Filesys::SmbClient' => 0,
        'Test::More' => 0,
        'Test::Differences' => 0,
        'File::Find' => 0,
        'File::Temp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Smbxfer-*' },
);
