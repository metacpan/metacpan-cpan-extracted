use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Async::Event::Interval',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/Async/Event/Interval.pm',
    ABSTRACT_FROM    => 'lib/Async/Event/Interval.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/async-event-interval/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/async-event-interval.git',
                web => 'https://github.com/stevieb9/async-event-interval',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Mock::Sub'        => 0,
        'Test::More'       => 0,
        'Test::SharedFork' => 0,
    },
    PREREQ_PM => {
        'IPC::Shareable'        => 1.13,
        'Parallel::ForkManager' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Async-Event-Interval-*' },
);
