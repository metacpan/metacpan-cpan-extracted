
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Add user-agent information to App::Cerberus",
  "AUTHOR" => "Dominik Schulz <tex\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Cerberus-Plugin-Woothee",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "App::Cerberus::Plugin::Woothee",
  "PREREQ_PM" => {
    "App::Cerberus::Plugin" => 0,
    "Woothee" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.01",
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



