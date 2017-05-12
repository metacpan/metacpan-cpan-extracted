use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::BCVI::AutoInstall',
    AUTHOR              => 'Andrew Ruthven <andrew@etc.gen.nz>',
    VERSION_FROM        => 'lib/App/BCVI/AutoInstall.pm',
    ABSTRACT_FROM       => 'lib/App/BCVI/AutoInstall.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-BCVI-AutoInstall-*' },
);
