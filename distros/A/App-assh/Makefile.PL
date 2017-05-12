
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A wrapper around autossh.",
  "AUTHOR" => "DBR <dbr\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "App-assh",
  "EXE_FILES" => [
    "bin/assh",
    "bin/assh"
  ],
  "LICENSE" => "unrestricted",
  "NAME" => "App::assh",
  "PREREQ_PM" => {
    "FindBin" => 0,
    "Moo" => 0,
    "MooX::Options" => 0,
    "MooX::Types::MooseLike::Base" => 0,
    "lib" => 0,
    "methods" => 0,
    "strict" => 0,
    "true" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Carp" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec::Functions" => 0,
    "List::Util" => 0,
    "Scalar::Util" => 0,
    "Test::CheckDeps" => "0.006",
    "Test::More" => "0.94",
    "Test::UseAllModules" => 0
  },
  "VERSION" => "1.1.2",
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



