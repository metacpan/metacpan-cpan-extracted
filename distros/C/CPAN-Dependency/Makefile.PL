use strict;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    NAME                => 'CPAN::Dependency',
    LICENSE             => 'perl',
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/CPAN/Dependency.pm',
    ABSTRACT_FROM       => 'lib/CPAN/Dependency.pm',
    PREREQ_PM => {
        # prereqs
        'CPANPLUS'      => '0.82',
        'DBI'           => '1.0',
        'DBD::SQLite'   => '1.0',
        'File::Slurp'   => '9999.12',
        'File::Spec'    => 0,
        'Module::CoreList'  => '2.12',
        'YAML'          => '0.66',

        # build/test prereqs
        'Test::Deep'    => 0,
        'Test::More'    => 0,
        'Test::Warn'    => 0,
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CPAN-Dependency-*' },
);
