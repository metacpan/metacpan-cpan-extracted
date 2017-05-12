#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Crypt::Skip32::Base32Crockford',
    VERSION_FROM => 'lib/Crypt/Skip32/Base32Crockford.pm',
    ABSTRACT     => 'Create url-safe encodings of 32-bit values',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Crypt::Skip32'             => '0',
        'Encode::Base32::Crockford' => '0',
        'Test::More'                => '0',
    }
);

