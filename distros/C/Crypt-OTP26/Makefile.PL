use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Crypt::OTP26',
    AUTHOR              => 'osfameron <osfameron@cpan.org>',
    VERSION_FROM        => 'lib/Crypt/OTP26.pm',
    ABSTRACT_FROM       => 'lib/Crypt/OTP26.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Crypt-OTP26-*' },
);
