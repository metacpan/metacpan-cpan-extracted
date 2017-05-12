
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Commandline app for base64 stuff",
  "AUTHOR" => "Glenn Fowler <cebjyre\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::Cmd" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Base64",
  "EXE_FILES" => [
    "bin/base64"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::Base64",
  "PREREQ_PM" => {
    "App::Cmd::Setup" => 0,
    "MIME::Base64" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "v0.1.0",
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



