
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Tea round organising IRC bot",
  "AUTHOR" => "Adam Taylor <ajct\@cpan.org>",
  "BUILD_REQUIRES" => {
    "English" => 0,
    "Test::Bot::BasicBot::Pluggable" => 0,
    "Test::MockModule" => 0,
    "Test::MockObject::Extends" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Bot-BasicBot-Pluggable-Module-Tea",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Bot::BasicBot::Pluggable::Module::Tea",
  "PREREQ_PM" => {
    "Bot::BasicBot::Pluggable::Module" => 0,
    "DateTime" => 0,
    "List::Util" => 0,
    "Moose" => 0
  },
  "VERSION" => "0.01",
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



