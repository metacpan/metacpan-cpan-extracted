
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Easy validates user input (usually from an HTML form) based on input profile for Dancer applications.",
  "AUTHOR" => "Natal Ng\303\251tal",
  "BUILD_REQUIRES" => {
    "Dancer::Test" => 0,
    "Data::Dumper" => 0,
    "JSON::Syck" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0,
    "YAML::Syck" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Dancer-Plugin-FormValidator",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dancer::Plugin::FormValidator",
  "PREREQ_PM" => {
    "Dancer" => "1.2001",
    "Dancer::Exception" => 0,
    "Dancer::Plugin" => 0,
    "Data::FormValidator" => 0,
    "Module::Load" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.131620",
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



