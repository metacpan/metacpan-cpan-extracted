
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Easily use Email::Sender from Dancer",
  "AUTHOR" => "Michael Alan Dorman <mdorman\@ironicdesign.com>",
  "BUILD_REQUIRES" => {
    "Email::Sender::Transport::Test" => 0,
    "Email::Simple" => 0,
    "IO::File" => 0,
    "Sub::Exporter" => 0,
    "Test::Compile" => 0,
    "Test::Fatal" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dancer-Plugin-EmailSender",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dancer::Plugin::EmailSender",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Dancer" => 0,
    "Dancer::Plugin" => 0,
    "Email::MIME" => 0,
    "Email::Sender::Simple" => 0,
    "Module::Load" => 0,
    "Scalar::Util" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.002",
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



