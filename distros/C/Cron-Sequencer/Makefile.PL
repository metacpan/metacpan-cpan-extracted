#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Cron::Sequencer',
    VERSION_FROM     => 'lib/Cron/Sequencer.pm',
    AUTHOR           => 'Nicholas Clark <nick@ccl4.org>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.20.0',
    PREREQ_PM => {
        'Algorithm::Cron'  => 0,
        'DateTime'         => 0,
        'JSON::MaybeXS'    => 0,
        'Try::Tiny'        => 0,
    },
    TEST_REQUIRES => {
        'Test::Deep'       => 0,
        'Test::Fatal'      => 0,
        'Test::More'       => 0,
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/Cron::Sequencer',
            bugtracker => 'https://github.com/Humanstate/cron-sequencer/issues',
            repository => 'https://github.com/Humanstate/cron-sequencer'
        },
    },
    EXE_FILES => [
        'bin/cron-sequencer',
    ],
);
