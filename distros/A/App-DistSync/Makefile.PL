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
        'URI'                   => 1.64,
        'YAML::Tiny'            => 1.00,
    };

my $exefiles = [qw(
        bin/distsync
    )];

WriteMakefile(
    'NAME'              => 'App::DistSync',
    'MIN_PERL_VERSION'  => 5.008001,
    'VERSION_FROM'      => 'lib/App/DistSync.pm',
    'ABSTRACT_FROM'     => 'lib/App/DistSync.pm',
    'BUILD_REQUIRES'    => $build_requires,
    'PREREQ_PM'         => $prereq_pm,
    'EXE_FILES'         => $exefiles,
    'AUTHOR'            => 'Serz Minus (Lepenkov Sergey) http://www.serzik.com <minus@mail333.com>',
    'LICENSE'           => 'gpl',
    'META_MERGE'        => {
        resources => {
            homepage        => 'http://app-distsync.sourceforge.net',
            repository      => 'https://svn.code.sf.net/p/app-distsync/code/trunk',
            license         => 'http://opensource.org/licenses/gpl-license.php',
        },
    },
);
1;
