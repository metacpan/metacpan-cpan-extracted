#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;
use Config;

die "Acme::Ghost is not supported on Microsoft Windows and Cygwin operating systems\n"
    if $^O eq 'MSWin32' or $^O =~ /cygwin/i;
die "Acme::Ghost does not support fork emulation\n" if $Config{d_pseudofork};

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Sys::Syslog'           => 0,
    };

WriteMakefile(
    'NAME'              => 'Acme::Ghost',
    'MIN_PERL_VERSION'  => 5.020001,
    'VERSION_FROM'      => 'lib/Acme/Ghost.pm',
    'ABSTRACT_FROM'     => 'lib/Acme/Ghost.pm',
    'BUILD_REQUIRES'    => $build_requires,
    'PREREQ_PM'         => $prereq_pm,
    'AUTHOR'            => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'           => 'perl',
    'META_MERGE'        => {
        'meta-spec' => {version => 2},
        prereqs     => {runtime => {requires => {perl => '5.020'}}},
        resources   => {
            homepage    => 'https://sourceforge.net/projects/acme-ghost/',
            license     => 'https://dev.perl.org/licenses',
            repository      => {
                    type => 'git',
                    url  => 'https://abalama@git.code.sf.net/p/acme-ghost/code',
                    web  => 'https://sourceforge.net/p/acme-ghost/code/ci/master/tree/',
                  },
        },
    },
    clean => {
        FILES => '*.pid *.tmp *.log',
    },
);

1;
