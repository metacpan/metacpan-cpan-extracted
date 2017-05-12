
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A multi-server client for speaking to App::Cerebrus",
  "AUTHOR" => "Clinton Gormley <drtech\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Cerberus-client",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "App::Cerberus::client",
  "PREREQ_PM" => {
    "Any::URI::Escape" => 0,
    "Carp" => 0,
    "HTTP::Tiny" => 0,
    "JSON" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.08",
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



