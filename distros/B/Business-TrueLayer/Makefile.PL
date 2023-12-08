#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Business::TrueLayer',
    VERSION_FROM     => 'lib/Business/TrueLayer.pm',
    AUTHOR           => 'Lee Johnson <leejo@cpan.org>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.20.0',
    PREREQ_PM => {
        'Moose'                 => "2.1400",
        'Mojolicious'           => "8.52",
        'Try::Tiny::SmartCatch' => "0.5",
        'IO::Socket::SSL'       => "2.009",
        'Crypt::JWT'            => '0.024',
        'Crypt::PK::ECC'        => '0.068',
        'Data::GUID'            => '0.049',
        'DateTime::Format::DateParse' => '0.05',
        'namespace::autoclean'  => '0.27',
        'Complete::Country'     => '0.003',
        'MooseX::Aliases'       => '0.11',
        'Carp'                  => 0,
        'JSON'                  => 0,
    },
    BUILD_REQUIRES => {
        'Test::Most'       => '0.33',
        'Test::MockObject' => '1.20140408',
        'Test::Warnings'   => '0.014',
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/Business::TrueLayer',
            bugtracker => 'https://github.com/Humanstate/business-truelayer/issues',
            repository => 'https://github.com/Humanstate/business-truelayer'
        },
    },
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
);

# vim: ts=4:sw=4:et
