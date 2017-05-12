#!/usr/bin/env perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

my( $mm ) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME          => 'Acme::CPANAuthors::Belarusian',
    VERSION_FROM  => 'lib/Acme/CPANAuthors/Belarusian.pm',
    ABSTRACT_FROM => 'lib/Acme/CPANAuthors/Belarusian.pm',
    AUTHOR        => 'Sergey Romanov <sromanov@cpan.org>',
    PREREQ_PM     => {
        'Acme::CPANAuthors' => '0.02',
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
                    repository => 'http://github.com/sergeyromanov/acme-cpanauthors-belarusian',
                    bugtracker => 'http://github.com/sergeyromanov/acme-cpanauthors-belarusian/issues'
                },
                no_index => {directory => [qw/t/]},
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {},
                test_requires      => {
                    'Test::More'        => '0.47',
                },
            },
        )
    ),
    test => { TESTS => 't/*.t' }
);
