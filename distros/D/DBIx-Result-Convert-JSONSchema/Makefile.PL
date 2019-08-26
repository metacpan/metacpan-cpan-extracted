#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'DBIx::Result::Convert::JSONSchema',
    ABSTRACT      => 'lib/DBIx/Result/Convert/JSONSchema.pm',
    VERSION_FROM  => 'lib/DBIx/Result/Convert/JSONSchema.pm',
    AUTHOR        => 'malishew <malishew@cpan.org>',
    LICENSE       => 'perl',
    PREREQ_PM     => {
        'Moo'             => 0,
        'Types::Standard' => 0,
        'Carp'            => 0,
        'Module::Load'    => 0,
        'Readonly'        => 0,
        'FindBin'         => 0,
    },
    BUILD_REQUIRES => {
        'Test::Most'          => 0,
        'DBIx::Class::Schema' => 0,
        'DBD::Mock'           => 0,
        'DBI'                 => 0,
    },
    META_MERGE => {
        requires => {
            perl => '5.010001',
        },
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/DBIx::Result::Convert::JSONSchema',
            bugtracker => 'https://github.com/Humanstate/p5-dbix-result-convert-jsonschema/issues',
            repository => 'https://github.com/Humanstate/p5-dbix-result-convert-jsonschema',
        },
    },
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
);

# vim: ts=4:sw=4:et
