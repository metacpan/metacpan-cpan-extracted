
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Moose config attribute loaded from file in home dir",
  "AUTHOR" => "Robin Smidsr\303\270d <robin\@smidsrod.no>",
  "BUILD_REQUIRES" => {
    "Config::Tiny" => 0,
    "English" => 0,
    "File::Spec" => 0,
    "Moose" => 0,
    "Test::More" => 0,
    "rlib" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Config-Role",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Config::Role",
  "PREREQ_PM" => {
    "Config::Any" => 0,
    "File::HomeDir" => 0,
    "Moose::Role" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "Path::Class::Dir" => 0,
    "Path::Class::File" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.1.1",
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



