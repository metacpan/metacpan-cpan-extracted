#!/usr/bin/env perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME          => 'App::Nopaste::Service::dpaste',
    VERSION_FROM  => 'lib/App/Nopaste/Service/dpaste.pm',
    ABSTRACT_FROM => 'lib/App/Nopaste/Service/dpaste.pm',
    AUTHOR        => 'Sergey Romanov <sromanov@cpan.org>',
    PREREQ_PM     => {
        'App::Nopaste' => '0.91',
        'JSON'         => '0',
    },
    ( $mm >= 6.31
        ? ( LICENSE => 'artistic_2' )
        : ()
    ),
    ( $mm < 6.46
        ? ()
        : ( META_MERGE => {
                resources => {
                    license    => 'http://dev.perl.org/licenses/',
                    repository => 'https://github.com/sergeyromanov/app-nopaste-service-dpaste',
                    bugtracker => 'https://github.com/sergeyromanov/app-nopaste-service-dpaste/issues',
                },
                no_index => {directory => [qw/t/]},
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {},
                test_requires      => {
                    'Test::More'   => '0.47',
                },
            },
        )
    ),
    test => { TESTS => 't/*.t' }
);
