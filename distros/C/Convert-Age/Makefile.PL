use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Convert::Age',
    AUTHOR              => 'Chris Fedde <cfedde@cpan.org>',
    VERSION_FROM        => 'lib/Convert/Age.pm',
    ABSTRACT_FROM       => 'lib/Convert/Age.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Convert-Age-*' },
);
