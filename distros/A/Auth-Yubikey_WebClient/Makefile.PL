use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Auth::Yubikey_WebClient',
    AUTHOR              => 'Phil Massyn <massyn@gmail.com>',
    VERSION_FROM        => 'lib/Auth/Yubikey_WebClient.pm',
    ABSTRACT_FROM       => 'lib/Auth/Yubikey_WebClient.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'LWP::UserAgent' => 1,
	'MIME::Base64' => 1,
	'Digest::HMAC_SHA1' => 1,
	'URI::Escape' => 1
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Auth-Yubikey_WebClient-*' },
);
