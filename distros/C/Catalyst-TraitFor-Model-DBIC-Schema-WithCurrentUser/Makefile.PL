
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Puts the context's current user into your Catalyst::Model::DBIC::Schema schema.",
  "AUTHOR" => "Amiri Barksdale <amiri\@roosterpirates.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-TraitFor-Model-DBIC-Schema-WithCurrentUser",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::TraitFor::Model::DBIC::Schema::WithCurrentUser",
  "PREREQ_PM" => {
    "Catalyst::Model::DBIC::Schema" => "0.60",
    "Catalyst::TraitFor::Model::DBIC::Schema::PerRequestSchema" => 0,
    "Moose::Role" => 0,
    "MooseX::MarkAsMethods" => "0.15",
    "namespace::autoclean" => 0
  },
  "TEST_REQUIRES" => {
    "Catalyst::Component" => 0,
    "DBIx::Class::Schema" => 0,
    "Moose" => 0,
    "Scalar::Util" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "lib" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.07",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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



