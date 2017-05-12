
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Easy SMS sending from Catalyst Apps.",
  "AUTHOR" => "Martin Atukunda <matlads\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-Model-SMS",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::Model::SMS",
  "PREREQ_PM" => {
    "Catalyst::Model::Adaptor" => 0,
    "Moose" => 0,
    "SMS::Send" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Catalyst" => 0,
    "Catalyst::Controller" => 0,
    "Catalyst::ScriptRunner" => 0,
    "Catalyst::Test" => 0,
    "FindBin" => 0,
    "Test::More" => 0,
    "Test::Pod" => "1.14",
    "Test::Pod::Coverage" => "1.04",
    "Test::WWW::Mechanize::Catalyst" => 0,
    "base" => 0,
    "namespace::autoclean" => 0,
    "ok" => 0
  },
  "VERSION" => "0.4",
  "test" => {
    "TESTS" => "t/*.t t/author/*.t"
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



