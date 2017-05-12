use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Cisco::Version',
    AUTHOR              => 'Maarten Wallraf <perl@2nms.com>',
    VERSION_FROM        => 'lib/Cisco/Version.pm',
    ABSTRACT_FROM       => 'lib/Cisco/Version.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Cisco-Version-*' },
);
