#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run author tests'
    unless $ENV{RELEASE_TESTING};

eval { require Test::Prereq; require Module::CoreList; Test::Prereq->import };
plan skip_all => 'Test::Prereq and Module::CoreList required' if $@;

# Check imports against declared prerequisites, excluding core and optional modules.
prereq_ok(
    'PREREQ_PM is in sync with actual module usage',
    [qw(
        TestCH
        Compress::LZ4 Compress::Zstd IO::Compress::Gzip
        Time::Moment
        Test::Pod Test::Pod::Coverage Test::CPAN::Changes
        Test::Prereq Test::Spelling Perl::Critic
        Test::Perl::Critic Devel::Cover
        ClickHouse::Encoder ClickHouse::Encoder::TCP
    ), keys %{Module::CoreList->find_version(5.010)}],
);

done_testing();
