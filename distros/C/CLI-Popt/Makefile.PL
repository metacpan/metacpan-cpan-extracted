#!/usr/bin/env perl

use strict;
use warnings;

use Config;

use ExtUtils::MakeMaker::CPANfile;
use ExtUtils::PkgConfig;

use constant _DEBUG => 0;

my $PKGCONFIG_LIB = 'popt';

my $libs = ExtUtils::PkgConfig->libs($PKGCONFIG_LIB) or do {
    die "pkg-config can’t find “$PKGCONFIG_LIB”. Is it installed?\n";
};

my $cflags = ExtUtils::PkgConfig->cflags($PKGCONFIG_LIB);

my @lddlflags = (
    $Config{lddlflags},
    ( _DEBUG ? '-fsanitize=address' : () ),
);

my @inc = (
    $cflags,
    '-Wall',
    ( _DEBUG ? '-fsanitize=address' : () ),
);

WriteMakefile(
    NAME              => 'CLI::Popt',
    VERSION_FROM      => 'lib/CLI/Popt.pm', # finds $VERSION
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CLI/Popt.pm', # retrieve abstract from module
       AUTHOR         => [
            'Felipe Gasper (FELIPE)',
        ],
      ) : ()
    ),
    LIBS              => $libs,
    LDDLFLAGS         => "@lddlflags",
    INC               => "@inc",
    LICENSE           => "perl_5",

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/FGasper/p5-CLI-Popt.git',
                web => 'https://github.com/FGasper/p5-CLI-Popt',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-CLI-Popt/issues',
            },
        },
    },
);
