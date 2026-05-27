#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run author tests'
    unless $ENV{RELEASE_TESTING};

eval { require Test::Prereq::Build; Test::Prereq::Build->import };
plan skip_all => 'Test::Prereq::Build required' if $@;

# Every module declared in PREREQ_PM / TEST_REQUIRES must actually be
# used somewhere, and every module used must be declared. Modules that
# are core, optional (lazy `require` of a recommended dep), or only
# pulled in by author tests are listed here so they are not flagged.
prereq_ok(
    '5.010',
    'PREREQ_PM is in sync with actual module usage',
    [qw(
        Compress::LZ4 Compress::Zstd IO::Compress::Gzip
        Time::Moment
        Test::Pod Test::Pod::Coverage Test::CPAN::Changes
        Test::Prereq::Build Test::Spelling Perl::Critic
        Test::Perl::Critic Devel::Cover
        ClickHouse::Encoder ClickHouse::Encoder::TCP
    )],
);

done_testing();
