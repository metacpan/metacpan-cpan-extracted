BEGIN {
  use strict; use warnings;
  unless(eval q{ use 5.006; 1}) {
    print "Perl 5.006 or better required\n";
    exit;
  }
}
# This file was automatically generated by Dist::Zilla::Plugin::Author::Plicease::MakeMaker v2.71.
use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT"           => "Alien::Build installer class for Module::Build",
  "AUTHOR"             => "Graham Ollis <plicease\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME"         => "Alien-Build-MB",
  "LICENSE"          => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME"             => "Alien::Build::MB",
  "PM"               => {
    "lib/Alien/Build/MB.pm" => "\$(INST_LIB)/Alien/Build/MB.pm"
  },
  "PREREQ_PM" => {
    "Alien::Build"  => "1.14",
    "Module::Build" => "0.37_01",
    "Path::Tiny"    => 0
  },
  "TEST_REQUIRES" => {
    "Alien::Build"  => "1.14",
    "Capture::Tiny" => 0,
    "File::chdir"   => 0,
    "Test2::V0"     => "0.000121"
  },
  "VERSION" => "0.09",
  "test"    => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "Alien::Build"  => "1.14",
  "Capture::Tiny" => 0,
  "File::chdir"   => 0,
  "Module::Build" => "0.37_01",
  "Path::Tiny"    => 0,
  "Test2::V0"     => "0.000121"
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);