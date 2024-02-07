#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Acrux'                 => 0.02,    # Ubuntu = libacrux-perl                RHEL = perl-Acrux
        'DBI'                   => 1.63,    # Ubuntu = libdbi-perl                  RHEL = perl-DBI
        'Mojolicious'           => 7.94,    # Ubuntu = libmojolicious-perl          RHEL = perl-Mojolicious
    };

WriteMakefile(
    'NAME'              => 'Acrux::DBI',
    'MIN_PERL_VERSION'  => 5.020001,
    'VERSION_FROM'      => 'lib/Acrux/DBI.pm',
    'ABSTRACT_FROM'     => 'lib/Acrux/DBI.pm',
    'BUILD_REQUIRES'    => $build_requires,
    'PREREQ_PM'         => $prereq_pm,
    'AUTHOR'            => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'           => 'perl',
    'META_MERGE'        => {
        'meta-spec' => {version => 2},
        prereqs     => {runtime => {requires => {perl => '5.020'}}},
        resources   => {
            homepage    => 'https://sourceforge.net/projects/acrux-dbi/',
            license     => 'https://dev.perl.org/licenses',
            repository      => {
                    type => 'git',
                    url  => 'https://abalama@git.code.sf.net/p/acrux-dbi/code',
                    web  => 'https://sourceforge.net/p/acrux-dbi/code/ci/master/tree/',
                  },
        },
    },
    clean => {
        FILES => '*.tmp *.db',
    },
);

1;
