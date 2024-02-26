#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Sys::Syslog'           => 0,
        'Config::General'       => 2.00,    # Ubuntu = libconfig-general-perl       RHEL = perl-Config-General
        'Sub::Util'             => 1.41,
    };

WriteMakefile(
    'NAME'              => 'Acrux',
    'MIN_PERL_VERSION'  => 5.020001,
    'VERSION_FROM'      => 'lib/Acrux.pm',
    'ABSTRACT_FROM'     => 'lib/Acrux.pm',
    'BUILD_REQUIRES'    => $build_requires,
    'PREREQ_PM'         => $prereq_pm,
    'AUTHOR'            => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'           => 'perl',
    'META_MERGE'        => {
        'meta-spec' => {version => 2},
        prereqs     => {runtime => {requires => {perl => '5.020'}}},
        resources   => {
            homepage    => 'https://sourceforge.net/projects/acrux/',
            license     => 'https://dev.perl.org/licenses',
            repository      => {
                    type => 'git',
                    url  => 'https://abalama@git.code.sf.net/p/acrux/code',
                    web  => 'https://sourceforge.net/p/acrux/code/ci/master/tree/',
                  },
        },
    },
    clean => {
        FILES => '*.tmp *.log *.pid',
    },
);

1;
