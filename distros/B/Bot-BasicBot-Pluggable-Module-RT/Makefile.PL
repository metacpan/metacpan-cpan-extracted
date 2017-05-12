
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'This is a plugin to access information about RT tickets on IRC',
  'AUTHOR' => 'Damien "dams" Krotkine',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'DISTNAME' => 'Bot-BasicBot-Pluggable-Module-RT',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Bot::BasicBot::Pluggable::Module::RT',
  'PREREQ_PM' => {
    'Bot::BasicBot::Pluggable::Module' => '0',
    'RT::Client::REST' => '0',
    'RT::Client::REST::Ticket' => '0'
  },
  'VERSION' => '0.20',
  'test' => {
    'TESTS' => 't/*.t'
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



