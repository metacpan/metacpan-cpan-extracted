use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::NoTalentAssClown',
    AUTHOR              => 'John Lifsey <nebulous@crashed.net>',
    VERSION_FROM        => 'lib/Acme/NoTalentAssClown.pm',
    ABSTRACT_FROM       => 'lib/Acme/NoTalentAssClown.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Lyrics::Fetcher' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-NoTalentAssClown-*' },
);
