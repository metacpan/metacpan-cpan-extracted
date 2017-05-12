
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Modules that \"split serialize\" data structures",
  "AUTHOR" => "Brendan Byrd <BBYRD\@CPAN.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {},
  "DISTNAME" => "Data-SplitSerializer",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "Data::SplitSerializer",
  "PREREQ_PM" => {
    "Hash::Merge" => "0.11",
    "Module::Runtime" => "0.006",
    "Moo" => "0.009001",
    "Parse::Path" => "0.90",
    "Try::Tiny" => "0.01",
    "Types::Standard" => "0.001",
    "namespace::clean" => "0.06",
    "sanity" => "0.91"
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => "0.01",
    "Test::CheckDeps" => "0.006",
    "Test::More" => "0.94",
    "Test::Most" => "0.01"
  },
  "VERSION" => "0.91",
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



