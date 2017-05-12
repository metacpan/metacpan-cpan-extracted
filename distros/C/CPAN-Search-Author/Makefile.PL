#!/usr/bin/perl

use 5.006;
use strict;use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'CPAN::Search::Author',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/CPAN/Search/Author.pm',
    ABSTRACT_FROM      => 'lib/CPAN/Search/Author.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'HTTP::Request'  => '1.40',
        'LWP::UserAgent' => '2.33',
        'HTML::Entities' => '1.35',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'CPAN-Search-Author-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'CPAN::Search::Author' => { file => 'lib/CPAN/Search/Author.pm', version => '0.04' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/Manwar/CPAN-Search-Author.git',
                web  => 'https://github.com/Manwar/CPAN-Search-Author',
            },
        }})
     : ()
    ),
);
