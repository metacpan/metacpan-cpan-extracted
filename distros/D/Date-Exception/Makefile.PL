#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Date::Exception',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Date/Exception.pm',
    ABSTRACT_FROM      => 'lib/Date/Exception.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moo'                  => '2.000000',
        'namespace::autoclean' => '0.28',
        'Throwable'            => '0.200011',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Date-Exception-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Date::Exception'                    => { file => 'lib/Date/Exception.pm'                  , version => '0.08' },
            'Date::Exception::InvalidDay'        => { file => 'lib/Date/Exception/InvalidDay.pm'       , version => '0.08' },
            'Date::Exception::InvalidDayCount'   => { file => 'lib/Date/Exception/InvalidDayCount.pm'  , version => '0.08' },
            'Date::Exception::InvalidMonth'      => { file => 'lib/Date/Exception/InvalidMonth.pm'     , version => '0.08' },
            'Date::Exception::InvalidMonthCount' => { file => 'lib/Date/Exception/InvalidMonthCount.pm', version => '0.08' },
            'Date::Exception::InvalidYear'       => { file => 'lib/Date/Exception/InvalidYear.pm'      , version => '0.08' },
            'Date::Exception::InvalidYearCount'  => { file => 'lib/Date/Exception/InvalidYearCount.pm' , version => '0.08' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Date-Exception.git',
                web  => 'https://github.com/manwar/Date-Exception',
            },
        }})
     : ()
    ),
);
