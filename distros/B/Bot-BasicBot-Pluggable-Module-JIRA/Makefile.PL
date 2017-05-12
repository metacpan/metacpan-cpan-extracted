
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Access JIRA via IRC!',
  'AUTHOR' => 'Mike Eldridge <diz@cpan.org>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Bot-BasicBot-Pluggable-Module-JIRA',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Bot::BasicBot::Pluggable::Module::JIRA',
  'PREREQ_PM' => {
    'Bot::BasicBot::Pluggable::Module' => '0.87',
    'DateTime' => '0.60',
    'DateTime::Format::MySQL' => '0.04',
    'JIRA::Client' => '0.24',
    'Lingua::StopWords::EN' => '0.08',
    'Moose' => '1.17',
    'MooseX::Traits' => '0.11',
    'POE' => '1.293',
    'Text::Xslate' => '0.2012',
    'Try::Tiny' => '0.06'
  },
  'VERSION' => '0.03',
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



