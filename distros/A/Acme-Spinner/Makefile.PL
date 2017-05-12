use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Spinner',
    AUTHOR              => 'Chris Fedde <cfedde at cpan.org>',
    VERSION_FROM        => 'lib/Acme/Spinner.pm',
    ABSTRACT_FROM       => 'lib/Acme/Spinner.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Spinner-*' },
);
