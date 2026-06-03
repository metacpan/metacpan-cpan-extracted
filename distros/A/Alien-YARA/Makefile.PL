#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
    NAME               => 'Alien::YARA',
    DISTNAME           => 'Alien-YARA',
    AUTHOR             => 'Mohammad S Anwar <mohammad.anwar@yahoo.com>',
    VERSION_FROM       => 'lib/Alien/YARA.pm',
    ABSTRACT_FROM      => 'lib/Alien/YARA.pm',
    LICENSE            => 'artistic_2',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.52',
        'Alien::Build::MM'    => '0.32',
        'FFI::CheckLib'       => '0.28',
    },
    BUILD_REQUIRES => {
        'Alien::Build'        => '0.32',
        'Mozilla::CA'         => '0',
    },
    PREREQ_PM => {
        'Alien::Base'         => '0.03',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    test  => { TESTS => 't/*.t' },
    clean => { FILES => 'Alien-YARA-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Alien::YARA' => {
                file      => 'lib/Alien/YARA.pm',
                version   => '0.0.1'
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Alien-YARA.git',
                web  => 'https://github.com/manwar/Alien-YARA',
            },
        }})
     : ()
    ),
));

sub MY::postamble { $abmm->mm_postamble }
