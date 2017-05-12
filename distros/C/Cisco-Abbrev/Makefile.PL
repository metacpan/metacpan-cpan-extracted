use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Cisco::Abbrev',
    AUTHOR              => 'kevin brintnall <kbrint@rufus.net>',
    VERSION_FROM        => 'lib/Cisco/Abbrev.pm',
    ABSTRACT_FROM       => 'lib/Cisco/Abbrev.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Cisco-Abbrev-*' },
    (MM->can('signature_target') ? (SIGN => 1) : ()),
);
