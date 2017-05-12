
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Easy Authentication for Dancer applications via Authen::Simple",
  "AUTHOR" => "Andrew Grangaard <spazm\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Authen::Simple::Adapter" => 0,
    "Dancer::Test" => 0,
    "Test::More" => 0,
    "base" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dancer-Plugin-Authen-Simple",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dancer::Plugin::Authen::Simple",
  "PREREQ_PM" => {
    "Authen::Simple" => 0,
    "Dancer" => 0,
    "Dancer::Plugin" => 0,
    "Memoize" => 0,
    "Module::Load" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.130500",
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



