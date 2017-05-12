
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Form validation and refilling",
  "AUTHOR" => "Chisel <chisel\@chizography.net>",
  "BUILD_REQUIRES" => {
    "Catalyst" => 0,
    "Catalyst::Plugin::FillInForm" => 0,
    "Catalyst::View::HTML::Template" => 0,
    "Catalyst::View::TT" => 0,
    "Class::C3" => 0,
    "Class::Inspector" => 0,
    "Data::FormValidator::Constraints" => 0,
    "FindBin" => 0,
    "Test::More" => 0,
    "Test::UseAllModules" => 0,
    "Test::WWW::Mechanize::Catalyst" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-Controller-Validation-DFV",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::Controller::Validation::DFV",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Catalyst::Controller" => 0,
    "Catalyst::Plugin::FillInForm" => 0,
    "Data::FormValidator" => 0,
    "Data::FormValidator::Constraints" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.0.8",
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



