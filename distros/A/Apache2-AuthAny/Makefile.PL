use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Apache2::AuthAny',
    AUTHOR              => 'Kim Goldov <kim@goldov.com>',
    VERSION_FROM        => 'lib/Apache2/AuthAny.pm',
    ABSTRACT_FROM       => 'lib/Apache2/AuthAny.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Apache2-AuthAny-*' },
);
