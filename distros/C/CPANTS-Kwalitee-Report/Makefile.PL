#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'CPANTS::Kwalitee::Report',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/CPANTS/Kwalitee/Report.pm',
    ABSTRACT_FROM      => 'lib/CPANTS/Kwalitee/Report.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => [ 'script/kwalitee-report' ],
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM              => {
        'Moo'              => '2.000000',
        'namespace::clean' => '0.24',
        'MooX::Options'    => '4.023',
        'List::Util'       => '1.33',
        'LWP::Simple'      => '6.15',
        'File::Temp'       => '0.2304',
        'XML::RSS::Parser' => '4.0',
        'Module::CPANTS::Kwalitee' => '0.97',
        'Module::CPANTS::Analyse'  => '0.97',
        'Parse::CPAN::Packages'    => '2.40',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'CPANTS-Kwalitee-Report-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/CPANTS-Kwalitee-Report.git',
                web  => 'https://github.com/manwar/CPANTS-Kwalitee-Report',
            },
        }})
     : ()
    ),
);
