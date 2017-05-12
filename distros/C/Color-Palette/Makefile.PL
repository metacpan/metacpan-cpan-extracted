
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "a set of named colors",
  "AUTHOR" => "Ricardo SIGNES <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Color-Palette",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Color::Palette",
  "PREREQ_PM" => {
    "Graphics::Color" => "0.21",
    "Graphics::Color::RGB" => 0,
    "List::MoreUtils" => 0,
    "Moose" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "Tie::Hash" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.96"
  },
  "VERSION" => "0.100003",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Graphics::Color" => "0.21",
  "Graphics::Color::RGB" => 0,
  "List::MoreUtils" => 0,
  "Moose" => 0,
  "MooseX::Types" => 0,
  "MooseX::Types::Moose" => 0,
  "Test::More" => "0.96",
  "Tie::Hash" => 0,
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



