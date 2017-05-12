
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "We are Austrian CPAN authors",
  "AUTHOR" => "Marcel Gruenauer <marcel\@cpan.org>, Philipp Gortan <gortan\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Acme-CPANAuthors-Austrian",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Acme::CPANAuthors::Austrian",
  "PREREQ_PM" => {
    "Acme::CPANAuthors::Register" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Acme::CPANAuthors" => 0,
    "Carp" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Scalar::Util" => 0,
    "Test::Differences" => 0,
    "Test::More" => "0.94"
  },
  "VERSION" => "1.131810",
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



