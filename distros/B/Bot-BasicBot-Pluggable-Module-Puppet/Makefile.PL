
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Ventriloquy via POE-flavored YAML over TCP",
  "AUTHOR" => "Mike Eldridge <diz\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Bot-BasicBot-Pluggable-Module-Puppet",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Bot::BasicBot::Pluggable::Module::Puppet",
  "PREREQ_PM" => {
    "Bot::BasicBot::Pluggable" => "0.87",
    "Bot::BasicBot::Pluggable::Module" => 0,
    "POE" => 0,
    "POE::Component::Server::TCP" => 0,
    "YAML" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.01",
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



