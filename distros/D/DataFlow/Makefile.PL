
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A framework for dataflow processing",
  "AUTHOR" => "Alexei Znamensky <russoz\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => "0.88",
    "Test::UseAllModules" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DataFlow",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "DataFlow",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "DateTime" => "0.51",
    "Encode" => 0,
    "Moose" => 0,
    "Moose::Autobox" => 0,
    "Moose::Exporter" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => "1.01",
    "MooseX::Aliases" => 0,
    "MooseX::Attribute::Chained" => 0,
    "MooseX::OneArgNew" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::IO" => 0,
    "MooseX::Types::Moose" => 0,
    "Queue::Base" => "2.1",
    "SQL::Abstract" => 0,
    "Scalar::Util" => 0,
    "Text::CSV::Encoded" => 0,
    "autodie" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.121830",
  "test" => {
    "TESTS" => "t/*.t"
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



