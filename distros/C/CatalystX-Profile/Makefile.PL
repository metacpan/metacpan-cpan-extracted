
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Profile your Catalyst application with Devel::NYTProf',
  'AUTHOR' => 'Oliver Charles <oliver.g.charles@googlemail.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'CatalystX-Profile',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'CatalystX::Profile',
  'PREREQ_PM' => {
    'Catalyst::Runtime' => '5.80020',
    'CatalystX::InjectComponent' => '0.024',
    'Devel::NYTProf' => '3.01',
    'Moose' => '0.93',
    'Sub::Identify' => '0.04',
    'namespace::autoclean' => '0.09'
  },
  'VERSION' => '0.02',
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



