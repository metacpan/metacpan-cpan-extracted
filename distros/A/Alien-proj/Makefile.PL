use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker;

my %common_reqs = (
    "Alien::Build" => "2.25",
    "ExtUtils::MakeMaker" => "6.52",
    "Alien::Build::MM" => "1.41",
    "File::Find::Rule" => 0,
    "PkgConfig" => 0.19026,
    "Alien::Build::Plugin::Cleanse::BuildDir" => 0,
    'Sort::Versions' => 0,
    'Alien::sqlite' => '1.06',
    "Path::Tiny" => 0,
    "File::Which" => 0,
    ($^O =~ /mswin/i) ? ("Alien::MSYS" => 0) : (),
    "Alien::Build::Plugin::PkgConfig::PPWrapper" => '0',
);

my %WriteMakefileArgs = (
    "ABSTRACT" => "Alien package for the PROJ library",
    "AUTHOR"   => 'Shawn Laffan <shawnlaffan@gmail.com>',
    "NAME"     => "Alien::proj",
    "VERSION_FROM" => "lib/Alien/proj.pm",
    "CONFIGURE_REQUIRES" => {
        %common_reqs,
        "PkgConfig"  => 0,
    },
    "BUILD_REQUIRES" => {
        %common_reqs,
        "File::Find::Rule" => 0,
        "FFI::CheckLib" => "0.23",
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
                url  => 'https://github.com/shawnlaffan/perl-alien-proj',
            },
            bugtracker => {
                web => 'https://github.com/shawnlaffan/perl-alien-proj/issues/',
            },
        },
        prereqs => {
            build => {
              suggests => {
                  'Alien::curl' => '0.08',
                  'Alien::libtiff' => 0,
              },
            },
            runtime => {
              suggests => {
                  'Alien::curl' => '0.08',
                  'Alien::libtiff' => 0,
              },
            },
        },
    },
    "DISTNAME" => "Alien-proj",
    "LICENSE"  => "perl",
);

use Alien::Build::MM;
my $abmm = Alien::Build::MM->new (
  clean_install => 1,
);
sub MY::install {
  $abmm->mm_install(@_);
}

%WriteMakefileArgs = $abmm->mm_args(%WriteMakefileArgs);

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
  $abmm->mm_postamble;
}
