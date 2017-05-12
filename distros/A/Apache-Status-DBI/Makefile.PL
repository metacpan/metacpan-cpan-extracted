use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Apache::Status::DBI',
    AUTHOR              => 'Tim Bunce <Tim.Bunce@pobox.com>',
    VERSION_FROM        => 'lib/Apache/Status/DBI.pm',
    ABSTRACT_FROM       => 'lib/Apache/Status/DBI.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DBI' => 1.49,
        # + Apache::Status or Apache2::Status
    },
    dist  => {
        DIST_DEFAULT=> 'clean distcheck disttest tardist',
        PREOP => '$(MAKE) -f Makefile.old distdir',
        COMPRESS => 'gzip -v9', SUFFIX => 'gz',
    },
    clean               => { FILES => 'Apache-Status-DBI-*' },
);
