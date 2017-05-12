
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'load CGI::Application::Plugin::TT with any TT-compatible class',
  'AUTHOR' => 'Christian Walde <walde.christian@googlemail.com>',
  'BUILD_REQUIRES' => {
    'CGI' => '0',
    'CGI::Application' => '0',
    'Test::Fatal' => '0',
    'Test::More' => '0',
    'Test::Most' => '0',
    'Test::Simple' => '0.96'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'CGI-Application-Plugin-TT-Any',
  'EXE_FILES' => [],
  'LICENSE' => 'unrestricted',
  'NAME' => 'CGI::Application::Plugin::TT::Any',
  'PREREQ_PM' => {
    'CGI::Application::Plugin::TT' => '0',
    'Carp' => '0',
    'Class::Load' => '0'
  },
  'VERSION' => '0.110080',
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



