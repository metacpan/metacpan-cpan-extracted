
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'The patriarch of IRC Bots',
  'AUTHOR' => 'Chris Prather <chris@prather.org>, Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>',
  'BUILD_REQUIRES' => {
    'Test::Deep' => '0.103',
    'Test::More' => '0.94'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Adam',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Adam',
  'PREREQ_PM' => {
    'MooseX::Aliases' => '0.10',
    'MooseX::Declare' => '0.34',
    'MooseX::Getopt' => '0.37',
    'MooseX::LogDispatch' => '1.2002',
    'MooseX::POE' => '0.214',
    'MooseX::SimpleConfig' => '0.09',
    'POE::Component::IRC' => '6.64',
    'Sub::Identify' => '0.04',
    'aliased' => '0.30',
    'namespace::autoclean' => '0.12'
  },
  'VERSION' => '0.91',
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



