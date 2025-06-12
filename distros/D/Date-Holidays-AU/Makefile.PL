#! /usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Date::Holidays::AU',
    AUTHOR        => 'David Dick <ddick@cpan.org>',
    VERSION_FROM  => 'lib/Date/Holidays/AU.pm',
    ABSTRACT_FROM => 'lib/Date/Holidays/AU.pm',  # retrieve abstract from module
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    (
        $ExtUtils::MakeMaker::VERSION >= 6.48
        ? ( 'MIN_PERL_VERSION' => '5.006' )
        : ()
    ),
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                url  => 'https://github.com/david-dick/date-holidays-au.git',
                web  => 'https://github.com/david-dick/date-holidays-au',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/david-dick/date-holidays-au/issues',
            },
        },
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Time::Local'  => 1.28,
        'Date::Easter' => 0,
        'Exporter'     => 0,
        'Carp'         => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Date-Holidays-AU-*' },
);
