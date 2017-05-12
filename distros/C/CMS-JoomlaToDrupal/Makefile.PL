use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CMS::JoomlaToDrupal',
    AUTHOR              => 'Hugh Esco <hesco@campaignfoundations.com>',
    VERSION_FROM        => 'lib/CMS/JoomlaToDrupal.pm',
    ABSTRACT_FROM       => 'lib/CMS/JoomlaToDrupal.pm',
    PL_FILES            => {},
    PREREQ_PM => {
               'DBI' => 0,
        'Test::More' => 0,
          'DateTime' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CMS-JoomlaToDrupal-*' },
);
