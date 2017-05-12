
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Easy validation and transformation of scalar tree structures",
  "AUTHOR" => "Oliver Charles",
  "BUILD_REQUIRES" => {
    "Moose" => "1.16",
    "Test::Fatal" => "0.003",
    "Test::More" => "0.96",
    "Test::Routine" => "0.004"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Data-TreeValidator",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::TreeValidator",
  "PREREQ_PM" => {
    "CGI::Expand" => "2.02",
    "Moose" => "1.16",
    "MooseX::Params::Validate" => "0.14",
    "MooseX::Types" => "0.24",
    "MooseX::Types::Structured" => "0.23",
    "Set::Object" => 0,
    "Sub::Exporter" => "0.982",
    "Throwable" => "0.102080",
    "Try::Tiny" => "0.07",
    "aliased" => "0.30",
    "namespace::autoclean" => "0.11"
  },
  "VERSION" => "0.04",
  "test" => {
    "TESTS" => "t/*.t t/Tests/Data/TreeValidator/*.t t/Tests/Data/TreeValidator/Result/*.t t/functional/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



