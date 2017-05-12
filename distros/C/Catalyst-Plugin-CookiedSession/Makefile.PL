#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Catalyst::Plugin::CookiedSession',
    VERSION_FROM => 'lib/Catalyst/Plugin/CookiedSession.pm',
    ABSTRACT     => 'Store sessions in a browser cookie',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Test::More'                 => '0',
        'Class::Accessor::Fast'      => '0',
        'Catalyst::Exception'        => '0',
        'Crypt::CBC'                 => '0',
        'Crypt::Rijndael'            => '0',
        'JSON::XS::VersionOneAndTwo' => '0',
        'MIME::Base64'               => '0',
        'NEXT'                       => '0',
    },
);
