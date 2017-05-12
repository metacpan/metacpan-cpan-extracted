#!/usr/bin/env perl

use 5.008007;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME         => 'App::TLSMe',
    VERSION_FROM => 'lib/App/TLSMe.pm',
    ABSTRACT     => 'TLS/SSL tunnel',
    AUTHOR       => 'Viacheslav Tykhanovskyi <vti@cpan.org>',

    ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

    (   $mm < 6.46
        ? ()
        : ( META_MERGE => {
                requires  => {perl => '5.008007'},
                resources => {
                    license    => 'http://dev.perl.org/licenses/',
                    repository => 'http://github.com/vti/app-tlsme',
                    bugtracker => 'http://github.com/vti/app-tlsme/issues'
                },
                no_index => {directory => [qw/t/]}
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),
    EXE_FILES => ['bin/tlsme'],

    PREREQ_PM => {
        'AnyEvent'      => 5.34,
        'IO::Handle'    => 0,
        'Net::SSLeay'   => 0,
        'Pod::Usage'    => 0,
        'Proc::Pidfile' => 0,
        'Scalar::Util'  => 0,
        'Test::More'    => 0,
        'Time::Piece'   => 0,
    },
    test => {TESTS => 't/*.t t/*/*.t'}
);
