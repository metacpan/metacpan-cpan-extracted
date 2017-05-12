
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "IRC frontend to Acme::MetaSyntactic",
  "AUTHOR" => "Philippe Bruhat (BooK) <book\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Acme::MetaSyntactic::MultiList" => 0,
    "File::Find" => 0,
    "List::Util" => 0,
    "Test::More" => "0.88"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Bot-BasicBot-Pluggable-Module-MetaSyntactic",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Bot::BasicBot::Pluggable::Module::MetaSyntactic",
  "PREREQ_PM" => {
    "Acme::MetaSyntactic" => 0,
    "Bot::BasicBot::Pluggable::Module" => 0,
    "Carp" => 0,
    "Text::Wrap" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.004",
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



