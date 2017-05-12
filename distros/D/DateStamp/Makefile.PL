use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DateStamp',
    AUTHOR              => 'Todd Wylie <perldev@monkeybytes.org>',
    VERSION_FROM        => 'lib/DateStamp.pm',
    ABSTRACT_FROM       => 'lib/DateStamp.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DateStamp-*' },
);
