#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Catalyst::Plugin::SimpleAuth',
    VERSION_FROM => 'lib/Catalyst/Plugin/SimpleAuth.pm',
    ABSTRACT     => 'Simple authentication for Catalyst',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Test::More'            => '0',
        'Class::Accessor::Fast' => '0',
        'Catalyst::Exception'   => '0',
        'Digest::SHA1'          => '0',
        'NEXT'                  => '0',
    },
);
