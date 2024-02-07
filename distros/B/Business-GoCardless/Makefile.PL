#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Business::GoCardless',
    VERSION_FROM     => 'lib/Business/GoCardless.pm',
    AUTHOR           => 'Lee Johnson <leejo@cpan.org>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.20.0',
    PREREQ_PM => {
        'Moo'                  => 1.006,
        'Carp'                 => 0, # Carp was first released with perl 5
        'Throwable'            => 0.200011,
        'POSIX'                => 0, # POSIX was first released with perl 5
        'MIME::Base64'         => 0, # MIME::Base64 was first released with perl v5.7.3
        'Digest::SHA'          => 0, # Digest::SHA was first released with perl v5.9.3
        'LWP::UserAgent'       => 6.00,
        'LWP::Protocol::https' => 6.00,
        'JSON'                 => 2.90,
    },
    BUILD_REQUIRES => {
        'Test::Most'       => 0.31,
        'Test::Deep'       => 0.112,
        'Test::Exception'  => 0.32,
        'FindBin'          => 0, # FindBin was first released with perl 5.00307
        'LWP::Simple'      => 6.00,
        'Test::MockObject' => 1.20140408,
        'Try::Tiny'        => 0.22,
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/Business::GoCardless',
            bugtracker => 'https://github.com/Humanstate/business-gocardless/issues',
            repository => 'https://github.com/Humanstate/business-gocardless'
        },
    },
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
);

# vim: ts=4:sw=4:et
