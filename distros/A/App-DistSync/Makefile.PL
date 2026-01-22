#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'HTTP::Message'         => 6.06,
        'File::Basename'        => 0,
        'File::Copy'            => 2.00,
        'File::Find'            => 1.00,
        'File::Path'            => 2.00,
        'File::Spec'            => 3.00,
        'LWP'                   => 6.08,
        'URI'                   => 1.70,
        'YAML::Tiny'            => 1.00,
    };

my $exefiles = [qw(
        bin/distsync
    )];

WriteMakefile(
    'NAME'              => 'App::DistSync',
    'MIN_PERL_VERSION'  => 5.020,
    'VERSION_FROM'      => 'lib/App/DistSync.pm',
    'ABSTRACT_FROM'     => 'lib/App/DistSync.pm',
    'BUILD_REQUIRES'    => $build_requires,
    'PREREQ_PM'         => $prereq_pm,
    'EXE_FILES'         => $exefiles,
    'AUTHOR'            => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'           => 'artistic_2',
    'META_MERGE'        => {
        'meta-spec' => {version => 2},
        prereqs     => {runtime => {requires => {perl => '5.020'}}},
        resources   => {
            homepage    => 'https://sourceforge.net/projects/app-distsync/',
            license     => 'https://opensource.org/license/artistic-2-0',
            repository      => {
                type => 'git',
                url  => 'https://abalama@git.code.sf.net/p/app-distsync/trunk',
                web  => 'https://sourceforge.net/p/app-distsync/trunk/ci/master/tree/',
            },
        },
    },
    clean => {
        FILES => '*.tmp',
    },
);

1;
