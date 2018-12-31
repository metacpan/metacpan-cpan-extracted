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
    ($^O =~ /mswin/i) ? ("Alien::MSYS" => 0) : (),
);

my %WriteMakefileArgs = (
    "ABSTRACT" => "Alien package for the Sqlite library",
    "AUTHOR"   => 'Shawn Laffan <shawnlaffan@gmail.com>',
    "NAME"     => "Alien::sqlite",
    "VERSION_FROM" => "lib/Alien/sqlite.pm",
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
                url  => 'https://github.com/shawnlaffan/perl-alien-sqlite',
            },
            bugtracker => {
                web => 'https://github.com/shawnlaffan/perl-alien-sqlite/issues/',
            },
        },
    },
    "DISTNAME" => "Alien-sqlite",
    "LICENSE"  => "perl",
);

use Alien::Build::MM;
my $abmm = Alien::Build::MM->new ();
%WriteMakefileArgs = $abmm->mm_args(%WriteMakefileArgs);

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
  $abmm->mm_postamble;
}
