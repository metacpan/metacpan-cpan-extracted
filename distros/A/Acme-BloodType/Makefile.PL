use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::BloodType',
    AUTHOR              => 'Andrew Rodland <ARODLAND@cpan.org>',
    VERSION_FROM        => 'lib/Acme/BloodType.pm',
    ABSTRACT_FROM       => 'lib/Acme/BloodType.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-BloodType-*' },
);
