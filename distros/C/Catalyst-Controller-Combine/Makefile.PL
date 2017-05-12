
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Combine JS/CSS Files",
  "AUTHOR" => "Wolfgang Kinkeldei <wolfgang\@kinkeldei.de>",
  "BUILD_REQUIRES" => {
    "Catalyst" => 0,
    "Catalyst::Runtime" => 0,
    "Catalyst::Test" => 0,
    "DateTime::Duration" => 0,
    "Exporter" => 0,
    "FindBin" => 0,
    "Path::Class::File" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "base" => 0,
    "namespace::autoclean" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-Controller-Combine",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::Controller::Combine",
  "PREREQ_PM" => {
    "Catalyst::Controller" => 0,
    "Catalyst::Runtime" => "5.80",
    "DateTime" => "0.72",
    "File::stat" => "1.00",
    "FindBin" => "1.47",
    "List::Util" => "1.21",
    "Moose" => "1.0",
    "Path::Class" => "0.23",
    "Test::Builder" => "0.86",
    "Test::Builder::Tester" => "1.18",
    "Test::Exception" => "0.27",
    "Test::Harness" => "3.14",
    "Test::More" => "0.86",
    "Text::Glob" => "0.08",
    "namespace::autoclean" => "0.09",
    "strict" => 0
  },
  "VERSION" => "0.15",
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



