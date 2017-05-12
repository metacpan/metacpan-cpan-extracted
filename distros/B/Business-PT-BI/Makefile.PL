use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Business::PT::BI',
    AUTHOR              => 'Jose Castro <cog@cpan.org>',
    VERSION_FROM        => 'lib/Business/PT/BI.pm',
    ABSTRACT_FROM       => 'lib/Business/PT/BI.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Business-PT-BI-*' },
);
