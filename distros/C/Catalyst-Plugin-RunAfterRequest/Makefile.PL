
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'run code after the response has been sent.',
  'AUTHOR' => 'Matt S Trout <mst@shadowcat.co.uk>, Edmund von der Burg <evdb@ecclestoad.co.uk>, Florian Ragwitz <rafl@debian.org>, Pedro Melo <melo@simplicidade.org>',
  'BUILD_REQUIRES' => {
    'Catalyst' => '0',
    'Catalyst::Controller' => '0',
    'Catalyst::Model' => '0',
    'Catalyst::Test' => '0',
    'FindBin' => '0',
    'List::MoreUtils' => '0',
    'Module::Find' => '0',
    'Moose' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Catalyst-Plugin-RunAfterRequest',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Catalyst::Plugin::RunAfterRequest',
  'PREREQ_PM' => {
    'Catalyst::Component::InstancePerContext' => '0',
    'Catalyst::Runtime' => '5.80004',
    'Moose::Role' => '0',
    'MooseX::Types::Moose' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '0.04',
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



