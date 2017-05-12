
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A generic and consistent interface for online payment services",
  "AUTHOR" => "Naveed Massjouni <naveedm9\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "AnyMerchant",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "AnyMerchant",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Moo::Role" => 0,
    "Scalar::Util" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.0002",
  "test" => {
    "TESTS" => ""
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



