# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.007.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Class::Rebirth.pm",
  "AUTHOR" => "Andreas Hernitscheck <ahernit\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Class-Rebirth",
  "LICENSE" => "lgpl",
  "NAME" => "Class::Rebirth",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "List::MoreUtils" => 0,
    "Scalar::Util" => 0
  },
  "VERSION" => "1.003",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Data::Dumper" => 0,
  "Exporter" => 0,
  "List::MoreUtils" => 0,
  "Scalar::Util" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
