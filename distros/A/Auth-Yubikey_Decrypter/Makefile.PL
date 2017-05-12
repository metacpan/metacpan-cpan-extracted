use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Auth::Yubikey_Decrypter',
    AUTHOR              => 'Phil Massyn <phil@massyn.net>',
    VERSION_FROM        => 'lib/Auth/Yubikey_Decrypter.pm',
    ABSTRACT_FROM       => 'lib/Auth/Yubikey_Decrypter.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Crypt::Rijndael' => 1,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Auth-Yubikey_Decrypter-*' },
);
