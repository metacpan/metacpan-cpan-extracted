use strict; use warnings;
BEGIN {
  unless(eval q{ use 5.006; 1}) {
    print "Perl 5.006 or better required\n";
    exit;
  }
}
# This file was automatically generated by Dist::Zilla::Plugin::Author::Plicease::MakeMaker v2.22.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Find or install libarchive version 3.x or better",
  "AUTHOR" => "Graham Ollis <plicease\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Alien::Build" => "0.71",
    "Alien::Build::MM" => "0.40",
    "Config" => 0,
    "ExtUtils::MakeMaker" => "6.52"
  },
  "CONFIGURE_REQUIRES" => {
    "Alien::Build" => "0.40",
    "Alien::Build::MM" => "0.71",
    "Alien::Build::Plugin::Build::SearchDep" => "0.35",
    "ExtUtils::CBuilder" => 0,
    "ExtUtils::MakeMaker" => "6.52"
  },
  "DISTNAME" => "Alien-Libarchive3",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Alien::Libarchive3",
  "PM" => {
    "lib/Alien/Libarchive.pm" => "\$(INST_LIB)/Alien/Libarchive.pm",
    "lib/Alien/Libarchive3.pm" => "\$(INST_LIB)/Alien/Libarchive3.pm"
  },
  "PREREQ_PM" => {
    "Alien::Base" => "0.038",
    "Path::Tiny" => 0
  },
  "TEST_REQUIRES" => {
    "Test2::V0" => "0.000060",
    "Test::Alien" => 0
  },
  "VERSION" => "0.29",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Alien::Base" => "0.038",
  "Alien::Build" => "0.71",
  "Alien::Build::MM" => "0.40",
  "Config" => 0,
  "ExtUtils::MakeMaker" => "6.52",
  "Path::Tiny" => 0,
  "Test2::V0" => "0.000060",
  "Test::Alien" => 0
);


# BEGIN code inserted by Dist::Zilla::Plugin::AlienBuild
use Alien::Build::MM;
my $abmm = Alien::Build::MM->new;
%WriteMakefileArgs = $abmm->mm_args(%WriteMakefileArgs);
# END code inserted by Dist::Zilla::Plugin::AlienBuild


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);


# BEGIN code inserted by Dist::Zilla::Plugin::AlienBuild
sub MY::postamble {
  $abmm->mm_postamble;
}
# END code inserted by Dist::Zilla::Plugin::AlienBuild

