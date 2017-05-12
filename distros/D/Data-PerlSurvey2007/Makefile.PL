use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::PerlSurvey2007',
    AUTHOR              => 'Andy Lester <andy@petdance.com>',
    VERSION_FROM        => 'PerlSurvey2007.pm',
    ABSTRACT_FROM       => 'PerlSurvey2007.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-PerlSurvey2007-*' },
);
