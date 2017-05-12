use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    NAME          => 'Data::EventStream',
    AUTHOR        => q{Pavel Shaydo <zwon@cpan.org>},
    VERSION_FROM  => 'lib/Data/EventStream.pm',
    ABSTRACT_FROM => 'lib/Data/EventStream.pm',
    LICENSE       => 'perl',
    PL_FILES      => {},
    PREREQ_PM     => {
        Moose => 0,
    },
    TEST_REQUIRES => {
        'Test::More'         => 0.94,
        'Test::Most'         => 0.22,
        'Test::FailWarnings' => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.64,
    },
    dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => 'Data-EventStream-*' },
    META_MERGE => {
        no_index => {
            file => 'README.pod'
        },
        resources => {

            homepage   => 'https://trinitum.github.io/perl-Data-EventStream/',
            bugtracker => 'https://github.com/trinitum/perl-Data-EventStream/issues',
            repository => 'git://github.com/trinitum/perl-Data-EventStream',

            license => 'http://dev.perl.org/licenses/',
        },
    },
);
