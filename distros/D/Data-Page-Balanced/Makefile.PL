# $Id: Makefile.PL 2 2007-10-27 22:08:58Z kim $

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Page::Balanced',
    AUTHOR              => 'Kim Ahlström <kim.ahlstrom@gmail.com>',
    VERSION_FROM        => 'lib/Data/Page/Balanced.pm',
    ABSTRACT_FROM       => 'lib/Data/Page/Balanced.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'                        => 0,
        'version'                           => 0,
        'Class::Accessor::Chained::Fast'    => 0,
        'Data::Page'                        => 2.00,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Page-Balanced-*' },
);
