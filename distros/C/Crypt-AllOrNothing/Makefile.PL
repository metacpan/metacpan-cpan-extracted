use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Crypt::AllOrNothing',
    AUTHOR              => 'Timothy Zander <timothy.zander@alum.rpi.edu>',
    VERSION_FROM        => 'lib/Crypt/AllOrNothing.pm',
    ABSTRACT_FROM       => 'lib/Crypt/AllOrNothing.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Crypt::OpenSSL::AES' => 0,
		'Crypt::AllOrNothing::Util' => 0.09,
		'Carp' => 0,
		'Crypt::Random' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Crypt-AllOrNothing-*' },
);
