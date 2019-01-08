use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker;

my %common_reqs = (
    "Alien::Build" => "1.41",
    "ExtUtils::MakeMaker" => "6.52",
    "Alien::Build::MM" => "1.41",
    "File::Find::Rule" => 0,
    "PkgConfig" => 0.19026,
    "Alien::Build::Plugin::Cleanse::BuildDir" => 0,
    'Sort::Versions' => 0,
    'Alien::sqlite' => '1.02',
    'Alien::proj' => 0,
    'Alien::freexl' => 0,
    'Alien::geos::af' => '1.007',
    ($^O =~ /mswin/i) ? ("Alien::MSYS" => 0) : (),
);

my %WriteMakefileArgs = (
    "ABSTRACT" => "Alien package for the Spatialite library",
    "AUTHOR"   => 'Shawn Laffan <shawnlaffan@gmail.com>',
    "NAME"     => "Alien::spatialite",
    "VERSION_FROM" => "lib/Alien/spatialite.pm",
    "CONFIGURE_REQUIRES" => {
        %common_reqs,
        "PkgConfig"  => 0,
    },
    "BUILD_REQUIRES" => {
        %common_reqs,
        "File::Find::Rule" => 0,
    },
    "TEST_REQUIRES" => {
        "Test::Alien" => 0,
        "FFI::CheckLib" => "0.23",
    },
    "PREREQ_PM" => {
        "Alien::Base"   => "1.41",
        "FFI::CheckLib" => "0.23",
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/shawnlaffan/perl-alien-spatialite',
            },
            bugtracker => {
                web => 'https://github.com/shawnlaffan/perl-alien-spatialite/issues/',
            },
        },
    },
    "DISTNAME" => "Alien-spatialite",
    "LICENSE"  => "perl",
);

use Alien::Build::MM;
my $abmm = Alien::Build::MM->new ();
%WriteMakefileArgs = $abmm->mm_args(%WriteMakefileArgs);

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
  $abmm->mm_postamble;
}
