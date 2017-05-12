
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "render Spreadsheet::Template templates in Catalyst",
  "AUTHOR" => "Jesse Luehrs <doy\@tozt.net>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-View-Spreadsheet-Template",
  "EXE_FILES" => [],
  "LICENSE" => "mit",
  "NAME" => "Catalyst::View::Spreadsheet::Template",
  "PREREQ_PM" => {
    "Catalyst::View" => 0,
    "Moose" => 0,
    "Path::Class" => 0,
    "Spreadsheet::Template" => 0,
    "Try::Tiny" => 0,
    "namespace::autoclean" => 0
  },
  "TEST_REQUIRES" => {
    "Catalyst" => 0,
    "Catalyst::Action::RenderView" => 0,
    "Catalyst::Controller" => 0,
    "Catalyst::Test" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Spreadsheet::ParseXLSX" => 0,
    "Test::More" => "0.88",
    "lib" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.02",
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



