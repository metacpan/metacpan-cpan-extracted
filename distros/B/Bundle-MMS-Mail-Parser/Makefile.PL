use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bundle::MMS::Mail::Parser',
    AUTHOR              => 'Rob Lee <robl@robl.co.uk>',
    VERSION_FROM        => 'lib/Bundle/MMS/Mail/Parser.pm',
    ABSTRACT_FROM       => 'lib/Bundle/MMS/Mail/Parser.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bundle-MMS-Mail-Parser-*' },
);
