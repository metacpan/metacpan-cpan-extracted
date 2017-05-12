#!/usr/bin/perl

use 5.006;
use strict;use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'CPAN::Search::Tester',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/CPAN/Search/Tester.pm',
    ABSTRACT_FROM      => 'lib/CPAN/Search/Tester.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM     => {
        'Moo'              => 0,
        'namespace::clean' => 0,
        'WWW::Mechanize'   => '1.60',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'CPAN-Search-Tester-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'CPAN::Search::Tester' => { file => 'lib/CPAN/Search/Tester.pm' , version => '0.04' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/Manwar/CPAN-Search-Tester.git',
                web  => 'https://github.com/Manwar/CPAN-Search-Tester',
            },
        }})
     : ()
    ),
);
