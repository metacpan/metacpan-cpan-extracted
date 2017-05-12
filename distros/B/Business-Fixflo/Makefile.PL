#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Business::Fixflo',
    VERSION_FROM     => 'lib/Business/Fixflo/Version.pm',
    AUTHOR           => 'Lee Johnson <leejo@cpan.org>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.10.1',
    PREREQ_PM => {
        'Moo'                  => 1.006,
        'Carp'                 => 0, # Carp was first released with perl 5
        'Throwable'            => 0.200011,
        'MIME::Base64'         => 0, # MIME::Base64 was first released with perl v5.7.3
        'LWP::UserAgent'       => 6.00,
        'LWP::Protocol::https' => 6.00,
        'JSON'                 => 2.90,
        'Try::Tiny'            => 0.22,
        'DateTime::Tiny'       => 1.04,
    },
    TEST_REQUIRES => {
        'Test::Most'       => 0.31,
        'Test::Deep'       => 0.112,
        'Test::Exception'  => 0.32,
        'Test::MockObject' => 1.20140408,
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/Business::Fixflo',
            bugtracker => 'https://github.com/Humanstate/business-fixflo/issues',
            repository => 'https://github.com/Humanstate/business-fixflo'
        },
    },
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
);

# vim: ts=4:sw=4:et
