use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker;

my %common_reqs = (
    "Alien::Build" => "0.32",
    "ExtUtils::MakeMaker" => "6.52",
    "Alien::Build::MM" => "0.32",
    "Alien::patch" => 0,
    "File::Find::Rule" => 0,
    ($^O =~ /mswin/i) ? ("Alien::MSYS" => 0) : (),
);

my %WriteMakefileArgs = (
    "ABSTRACT" => "Alien package for the Geospatial Data Abstraction Library (GDAL)",
    "AUTHOR"   => 'Shawn Laffan <shawnlaffan@gmail.com>',
    "NAME"     => "Alien::gdal",
    "VERSION_FROM" => "lib/Alien/gdal.pm",
    "CONFIGURE_REQUIRES" => {
        %common_reqs,
        "PkgConfig"  => 0,
        "HTTP::Tiny" => 0.044,  #  something, somewhere needs this version, need to track it down
    },
    "BUILD_REQUIRES" => {
        %common_reqs,
    },
    "TEST_REQUIRES" => {
        "Test::CChecker" => 0,
    },
    "PREREQ_PM" => {
        "Alien::Base" => "0.038",
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/shawnlaffan/perl-alien-gdal',
            },
            bugtracker => {
                web => 'https://github.com/shawnlaffan/perl-alien-gdal/issues/',
            },
        },
    },
    "DISTNAME" => "Alien-gdal",
    "LICENSE"  => "perl",
);

use Alien::Build::MM;
my $abmm = Alien::Build::MM->new ();
%WriteMakefileArgs = $abmm->mm_args(%WriteMakefileArgs);

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
  $abmm->mm_postamble;
}
