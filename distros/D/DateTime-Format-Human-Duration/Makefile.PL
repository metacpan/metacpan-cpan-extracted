use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DateTime::Format::Human::Duration',
    AUTHOR              => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM        => 'lib/DateTime/Format/Human/Duration.pm',
    ABSTRACT_FROM       => 'lib/DateTime/Format/Human/Duration.pm',
    PL_FILES            => {},
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'File::Spec' => 0,
        'FindBin'    => 0,
    },
    PREREQ_PM => { },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/mstratman/DateTime-Format-Human-Duration',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DateTime-Format-Human-Duration-*' },
);
