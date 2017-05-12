
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Command line scrobbling app",
  "AUTHOR" => "Adam Taylor <ajct\@cpan.org>",
  "BUILD_REQUIRES" => {
    "English" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Scrobble",
  "EXE_FILES" => [
    "bin/scrobble",
    "bin/scrobble"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::Scrobble",
  "PREREQ_PM" => {
    "Data::Dump" => 0,
    "File::HomeDir" => 0,
    "Module::PluginFinder" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::Getopt::Dashes" => 0,
    "MooseX::SimpleConfig" => 0,
    "Net::LastFM::Submission" => 0,
    "WWW::BBC::TrackListings" => 0,
    "WWW::Mixcloud" => 0,
    "namespace::autoclean" => 0,
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



