use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Easy installation of the GSL library",
  "AUTHOR" => "Joel A. Berger <joel.a.berger\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Alien::Build" => "2.21",
    "Alien::Build::MM" => "2.21",
    "ExtUtils::MakeMaker" => "6.52"
  },
  "CONFIGURE_REQUIRES" => {
    "Alien::Build" => "2.21",
    "Alien::Build::MM" => "2.21",
    "ExtUtils::MakeMaker" => "6.52"
  },
  "DISTNAME" => "Alien-GSL",
  "LICENSE" => "perl",
  "NAME" => "Alien::GSL",
  "PREREQ_PM" => {
    "Alien::Base" => "2.21",
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.52",
    "Test2::V0" => 0,
    "Test::Alien" => 0,
    "Test::Alien::Diag" => 0,
  },
  "VERSION_FROM" => "lib/Alien/GSL.pm",
  "test" => {
    "TESTS" => "t/*.t"
  },

  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      bugtracker => {
        web  => 'https://github.com/PerlAlien/Alien-GSL/issues',
      },
      homepage => 'https://metacpan.org/pod/Alien::GSL',
      repository => {
        type => 'git',
        url  => 'https://github.com/PerlAlien/Alien-GSL.git',
        web  => 'https://github.com/PerlAlien/Alien-GSL',
      },
      x_IRC => "irc://irc.perl.org/#native",
    },
  },

);


my %FallbackPrereqs = (
  "Alien::Base" => "2.21",
  "Alien::Build" => "2.21",
  "Alien::Build::MM" => "2.21",
  "ExtUtils::MakeMaker" => "6.52",
  "File::Spec" => 0,
  "Sort::Versions" => 0,
  "Test::More" => 0
);


use Alien::Build::MM;
my $abmm = Alien::Build::MM->new;
%WriteMakefileArgs = $abmm->mm_args(%WriteMakefileArgs);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

WriteMakefile(%WriteMakefileArgs);


{ package
    MY;
  sub postamble {
    $abmm->mm_postamble(@_);
  }
  sub install {
    $abmm->can('mm_install')
      ? $abmm->mm_install(@_)
      : shift->SUPER::install(@_);
  }
}
