
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Simple. Git-based. Notes.",
  "AUTHOR" => "William Wolf <throughnothing\@gmail.com>, Naveed Massjouni <naveedm9\@gmail.com>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Notes",
  "EXE_FILES" => [
    "bin/notes"
  ],
  "LICENSE" => "unrestricted",
  "NAME" => "App::Notes",
  "PREREQ_PM" => {
    "App::Rad" => 0,
    "Capture::Tiny" => 0,
    "Git::Repository" => 0,
    "List::MoreUtils" => 0,
    "Path::Class" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.013",
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



