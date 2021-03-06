# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.010.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Validation framework that can be configured with YAML files",
  "AUTHOR" => "Renee Baecker <reneeb\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Data-Validate-WithYAML",
  "LICENSE" => "artistic_2",
  "NAME" => "Data::Validate::WithYAML",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Scalar::Util" => "1.5",
    "YAML::Tiny" => "1.70"
  },
  "TEST_REQUIRES" => {
    "Data::Dumper" => 0,
    "File::Basename" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.20",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Data::Dumper" => 0,
  "File::Basename" => 0,
  "File::Temp" => 0,
  "FindBin" => 0,
  "Scalar::Util" => "1.5",
  "Test::Exception" => 0,
  "Test::More" => 0,
  "YAML::Tiny" => "1.70"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
