#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    'NAME'         => 'Alt::Template::Plugin::JSON::Moo',
    'VERSION_FROM' => 'lib/Alt/Template/Plugin/JSON/Moo.pm',
    'PREREQ_PM' => {
        'Moo'               => '1,000000',
        'Type::Tiny'        => '1.000006',
        'Template'          => '2.20',
        'JSON'              => '2.12',
        'namespace::clean'  => 0,
        'Carp'              => 0,
    },

    'CONFIGURE_REQUIRES' => {
        'ExtUtils::MakeMaker' => '6.64',
    },

    'TEST_REQUIRES' => {
        'Test::More'    => '0',
    },

    'LICENSE' => 'MIT',
    'MIN_PERL_VERSION' => '5.008001',

    'META_MERGE' => {
        'meta-spec' => { version => 2 },
        resources => {
            repository  => {
                type => 'git',
                web  => 'https://github.com/tehmoth/Alt-Template-Plugin-JSON-Moo',
                url  => 'https://github.com/tehmoth/Alt-Template-Plugin-JSON-Moo.git',
            },
        },
    },

    'INSTALLDIRS' => 'site',
    'EXE_FILES'   => [],
    'PL_FILES'    => {}
);

unless ( eval { require JSON::XS } ) {
warn <<WARN
JSON::XS is reccomended, you should probably install it for better performance.
WARN
}
