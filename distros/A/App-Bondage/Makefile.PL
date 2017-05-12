
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A featureful IRC bouncer based on POE::Component::IRC',
  'AUTHOR' => 'Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::Script' => '1.07'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-Bondage',
  'EXE_FILES' => [
    'bin/bondage'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::Bondage',
  'PREREQ_PM' => {
    'POE::Component::Client::DNS' => '0.99',
    'POE::Component::IRC' => '6.06',
    'POE::Filter::IRCD' => '2.34',
    'Proc::Daemon' => '0',
    'YAML::XS' => '0'
  },
  'VERSION' => '0.4.11',
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



