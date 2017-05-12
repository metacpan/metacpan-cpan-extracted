use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Apache::Lint',
    AUTHOR              => 'Andy Lester <andy@petdance.com>',
    VERSION_FROM        => 'Lint.pm',
    ABSTRACT_FROM       => 'Lint.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'HTML::Lint' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Apache-Lint-*' },
);
