
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Hook system with asynchronous capabilities",
  "AUTHOR" => "Pedro Melo <melo\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::Deep" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "0.98"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Async-Hooks",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "Async::Hooks",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Mo" => "0.30",
    "namespace::clean" => 0
  },
  "VERSION" => "0.16",
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



