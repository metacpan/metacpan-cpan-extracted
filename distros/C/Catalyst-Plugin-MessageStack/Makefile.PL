
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A Catalyst plugin for gracefully handling messaging (and more) that follows the Post/Redirect/Get pattern.",
  "AUTHOR" => "J. Shirley <jshirley\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Catalyst" => 0,
    "Catalyst::Controller" => 0,
    "Catalyst::Model" => 0,
    "Catalyst::Plugin::Session::State" => 0,
    "Catalyst::Test" => 0,
    "Data::Dump" => 0,
    "FindBin" => 0,
    "Message::Stack::Message" => 0,
    "Test::More" => 0,
    "Test::WWW::Mechanize::Catalyst" => 0,
    "base" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-Plugin-MessageStack",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::Plugin::MessageStack",
  "PREREQ_PM" => {
    "Catalyst::Plugin::Session" => 0,
    "Catalyst::Plugin::Session::State::Cookie" => 0,
    "Catalyst::Runtime" => 0,
    "MRO::Compat" => 0,
    "Message::Stack" => "0.21",
    "Scalar::Util" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.03",
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



