
use strict;
use warnings;

use 5.006001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Container class for currency conversion/formatting",
  "AUTHOR" => "Christopher H. Laco <claco _at_ chrislaco.com>, Mariano Wahlmann <dichoso _at_ gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Data-Currency",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::Currency",
  "PREREQ_PM" => {
    "Class::Accessor::Grouped" => 0,
    "Class::Inspector" => 0,
    "Finance::Currency::Convert::WebserviceX" => 0,
    "Locale::Currency" => 0,
    "Locale::Currency::Format" => 0,
    "Scalar::Util" => 0,
    "Test::Exception" => 0,
    "Test::MockObject" => 0,
    "Test::More" => 0
  },
  "TEST_REQUIRES" => {
    "Pod::Coverage::TrustPod" => 0,
    "Test::Perl::Critic" => 0
  },
  "VERSION" => "0.06000",
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



