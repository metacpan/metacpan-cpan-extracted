
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Extensible system to provide bash completion",
  "AUTHOR" => "Pedro Melo <melo\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Temp" => 0,
    "Test::Deep" => 0,
    "Test::More" => "0.98"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Bash-Completion",
  "EXE_FILES" => [
    "bin/bash-complete",
    "bin/setup-bash-complete"
  ],
  "LICENSE" => "artistic_2",
  "NAME" => "Bash::Completion",
  "PREREQ_PM" => {
    "File::Spec" => 0,
    "File::Spec::Functions" => 0,
    "Getopt::Long" => "2.36",
    "List::MoreUtils" => 0,
    "Module::Load" => "0.22",
    "Module::Pluggable" => 0,
    "parent" => 0
  },
  "VERSION" => "0.008",
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



