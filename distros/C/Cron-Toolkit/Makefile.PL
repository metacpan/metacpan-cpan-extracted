use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Cron::Toolkit',
    AUTHOR              => 'Nathaniel J Graham <ngraham@cpan.org>',
    VERSION_FROM        => 'lib/Cron/Toolkit.pm',
    ABSTRACT_FROM       => 'lib/Cron/Toolkit.pm',
    LICENSE             => 'artistic_2',
    PL_FILES            => {},
    PREREQ_PM => {
        'Time::Moment' => 0,
        'DateTime::TimeZone' => 0,
        'JSON::MaybeXS' => 0,
        'List::Util' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Cron-Toolkit-*' },
    (eval { ExtUtils::MakeMaker->VERSION('6.64') } ? (TEST_REQUIRES => {
        'Test::Pod' => 0,
        'Test::Pod::Coverage' => 0,
    }) : ()),
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/nathanielgraham/cron-toolkit-perl.git',
                web  => 'https://github.com/nathanielgraham/cron-toolkit-perl',
            },
        },
    },
);
