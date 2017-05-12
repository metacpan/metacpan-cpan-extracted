
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A Dancer2 plugin to easily add Google Analytics code.",
  "AUTHOR" => "Cesare Gargano <garcer\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Dancer2-Plugin-GoogleAnalytics",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dancer2::Plugin::GoogleAnalytics",
  "PREREQ_PM" => {
    "Dancer2" => 0,
    "Dancer2::Core::Hook" => 0,
    "Dancer2::Plugin" => 0,
    "Moo::Role" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "File::Spec::Functions" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "List::Util" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Dancer2" => 0,
  "Dancer2::Core::Hook" => 0,
  "Dancer2::Plugin" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "File::Spec::Functions" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "List::Util" => 0,
  "Module::Build" => "0.3601",
  "Moo::Role" => 0,
  "Test::More" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



