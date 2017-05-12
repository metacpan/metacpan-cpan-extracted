
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Interact with the Apache BalancerManager",
  "AUTHOR" => "Arthur Axel \"fREW\" Schmidt <frioux+cpan\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::LWP::UserAgent" => "0.014",
    "Test::More" => "0.98"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Apache-BalancerManager",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Apache::BalancerManager",
  "PREREQ_PM" => {
    "LWP::UserAgent" => "6.04",
    "List::Util" => 0,
    "Moo" => "1.000007",
    "URI" => "1.60",
    "Web::Scraper" => "0.37"
  },
  "VERSION" => "0.001002",
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



