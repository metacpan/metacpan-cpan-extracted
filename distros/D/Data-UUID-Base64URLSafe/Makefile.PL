#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Data::UUID::Base64URLSafe',
    VERSION_FROM => 'lib/Data/UUID/Base64URLSafe.pm',
    ABSTRACT     => 'URL-safe UUIDs',
    LICENSE      => 'perl',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    PREREQ_PM    => {
        'Test::More'            => '0.01',
        'Data::UUID'            => '0',
        'MIME::Base64::URLSafe' => '0',
    },
);

