use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'BLASTaid',
    AUTHOR              => 'Todd Wylie <perldev@monkeybytes.org>',
    VERSION_FROM        => 'lib/BLASTaid.pm',
    ABSTRACT_FROM       => 'lib/BLASTaid.pm',
    EXE_FILES           => ['bin/BLASTaid'],
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'BLASTaid-*' },
);
