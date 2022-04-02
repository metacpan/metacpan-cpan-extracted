use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker;

my %common_reqs = (
    "Alien::Build" => "2.25",
    "ExtUtils::MakeMaker" => "6.52",
    "Alien::Build::MM" => "1.41",
    ($^O =~ /mswin/i) ? ("Alien::MSYS" => 0) : (),
);

my %WriteMakefileArgs = (
    "ABSTRACT" => "Alien package for the patchelf utility",
    "AUTHOR"   => 'Shawn Laffan <shawnlaffan@gmail.com>',
    "NAME"     => "Alien::patchelf",
    "VERSION_FROM" => "lib/Alien/patchelf.pm",
    "CONFIGURE_REQUIRES" => {
        %common_reqs,
        'Alien::Build::Plugin::Download::GitHub' => '0',
    },
    "BUILD_REQUIRES" => {
        %common_reqs,
        "Alien::Build::Plugin::Download::GitHub" => '0',
    },
    "TEST_REQUIRES" => {
        "Test::Alien" => 0,
    },
    "PREREQ_PM" => {
        "Alien::Base"   => "1.41",
        "Capture::Tiny" => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/PerlAlien/Alien-patchelf',
            },
            bugtracker => {
                web => 'https://github.com/PerlAlien/Alien-patchelf/issues/',
            },
        },
    },
    "DISTNAME" => "Alien-patchelf",
    "LICENSE"  => "perl",
);

use Alien::Build::MM;
my $abmm = Alien::Build::MM->new ();
%WriteMakefileArgs = $abmm->mm_args(%WriteMakefileArgs);

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
  $abmm->mm_postamble;
}
