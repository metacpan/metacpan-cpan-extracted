
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Module for testing various CPAN web interfaces and their POD interactions",
  "AUTHOR" => "Brendan Byrd <BBYRD\@CPAN.org>",
  "BUILD_REQUIRES" => {
    "Test::CheckDeps" => "0.002",
    "Test::More" => "0.88",
    "Test::UseAllModules" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Acme-Web-PodDisplay",
  "EXE_FILES" => [],
  "LICENSE" => "unrestricted",
  "NAME" => "Acme::Web::PodDisplay",
  "PREREQ_PM" => {},
  "VERSION" => "0.91",
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



