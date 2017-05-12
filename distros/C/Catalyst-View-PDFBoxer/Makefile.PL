
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Runs view output through PDF::Boxer and sets response content-type if not already set.",
  "AUTHOR" => "Jason Galea <lecstor\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Catalyst" => 0,
    "Catalyst::Controller" => 0,
    "Catalyst::View::TT" => 0,
    "FindBin" => 0,
    "Moose" => 0,
    "Path::Class" => 0,
    "Test::More" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-View-PDFBoxer",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::View::PDFBoxer",
  "PREREQ_PM" => {
    "Moose::Role" => 0,
    "PDF::Boxer" => "0.003",
    "PDF::Boxer::SpecParser" => 0,
    "namespace::clean" => 0
  },
  "VERSION" => "0.001",
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



