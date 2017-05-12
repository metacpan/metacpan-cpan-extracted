
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "JSON transformer",
  "AUTHOR" => "Kang-min Liu <gugod\@gugod.org>",
  "BUILD_REQUIRES" => {
    "IO::String" => 0,
    "Test::More" => 0,
    "strict" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-jt",
  "EXE_FILES" => [
    "bin/jt"
  ],
  "LICENSE" => "mit",
  "NAME" => "App::jt",
  "PREREQ_PM" => {
    "Hash::Flatten" => 0,
    "IO::Handle" => 0,
    "JSON::PP" => 0,
    "JSON::Path" => 0,
    "List::MoreUtils" => 0,
    "Moo" => 0,
    "MooX::Options" => 0,
    "Pod::Usage" => 0,
    "Text::CSV" => 0
  },
  "VERSION" => "0.43",
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



