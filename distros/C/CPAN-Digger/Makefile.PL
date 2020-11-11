use strict;
use warnings;

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'CPAN::Digger',
    AUTHOR        => 'Gabor Szabo <gabor@szabgab.com>',
    VERSION_FROM  => 'lib/CPAN/Digger.pm',
    ABSTRACT_FROM => 'lib/CPAN/Digger.pm',
    LICENSE       => 'perl',
    EXE_FILES     => ['bin/cpan-digger'],
    dist          => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    PREREQ_PM => {
        'Capture::Tiny'    => 0,
        'DBI'              => 0,
        'DBD::SQLite'      => 0,
        'Log::Log4perl'    => 0,
        'LWP::UserAgent'   => 0,
        'MetaCPAN::Client' => 0,
        'Path::Tiny'       => 0,
    },
    TEST_REQUIRES => {
        'Test::More'    => 0,
        'Mock::Quick'   => 0,
        'Storable'      => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/szabgab/CPAN-Digger.git',
                web  => 'https://github.com/szabgab/CPAN-Digger',
            },
            bugtracker => {web => 'https://github.com/szabgab/CPAN-Digger/issues'},
            homepage   => 'https://perlmaven.com/cpan-digger',
        },
    },
);
