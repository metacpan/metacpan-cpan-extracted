use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Crypt::Juniper',
    AUTHOR              => 'kevin brintnall <kbrint@rufus.net>',
    VERSION_FROM        => 'lib/Crypt/Juniper.pm',
    ABSTRACT_FROM       => 'lib/Crypt/Juniper.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::Exception' => 0,
        'Test::More' => 0,
        'Carp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Crypt-Juniper-*' },
    (MM->can('signature_target') ? (SIGN => 1) : ()),
);
