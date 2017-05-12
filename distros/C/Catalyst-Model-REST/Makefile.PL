
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "REST model class for Catalyst",
  "AUTHOR" => "Kaare Rasmussen <kaare at cpan dot net>",
  "BUILD_REQUIRES" => {
    "Data::Serializer" => 0,
    "Data::Serializer::JSON" => 0,
    "Data::Serializer::XML::Simple" => 0,
    "Data::Serializer::YAML" => 0,
    "JSON" => "2.00",
    "Module::Build" => "0.3601",
    "Test::More" => "0.88",
    "XML::Simple" => 0,
    "YAML" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Catalyst-Model-REST",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::Model::REST",
  "PREREQ_PM" => {
    "Catalyst::Model" => 0,
    "Moose" => 0,
    "Role::REST::Client" => 0
  },
  "VERSION" => "0.27",
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



