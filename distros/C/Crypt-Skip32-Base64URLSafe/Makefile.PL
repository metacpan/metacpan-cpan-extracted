#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Crypt::Skip32::Base64URLSafe',
    VERSION_FROM => 'lib/Crypt/Skip32/Base64URLSafe.pm',
    ABSTRACT     => 'Create URL-safe encodings of 32-bit values',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Crypt::Skip32'         => '0',
        'MIME::Base64::URLSafe' => '0',
        'Test::More'            => '0',
    }
);

