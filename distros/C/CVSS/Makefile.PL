#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'CVSS',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    VERSION_FROM       => 'lib/CVSS.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => ['bin/cvss'],
    MIN_PERL_VERSION   => 5.010,
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '0'},
    TEST_REQUIRES      => {'Test::More' => '0', 'JSON::PP' => '0'},
    PREREQ_PM          => {'List::Util' => '0', 'JSON::PP' => '0'},
    META_MERGE         => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-CVSS/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-CVSS',
                web  => 'https://github.com/giterlizzi/perl-CVSS'
            },
        },
        x_purl => 'pkg:cpan/GDT/CVSS'
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'CVSS-*'},
);
