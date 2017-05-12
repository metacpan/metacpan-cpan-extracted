
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Speedier interface to HTML::FormFu for Catalyst',
  'AUTHOR' => 'Peter Shangov <pshangov@yahoo.com>',
  'BUILD_REQUIRES' => {
    'Catalyst' => '0',
    'Catalyst::Controller' => '0',
    'Catalyst::Engine::HTTP' => '0',
    'Catalyst::Model::DBIC::Schema' => '0',
    'Catalyst::Restarter' => '0',
    'Catalyst::Runtime' => '5.80',
    'Catalyst::Test' => '0',
    'Catalyst::View::TT' => '0',
    'DBIx::Class::Candy' => '0',
    'DBIx::Class::Schema' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'FindBin' => '0',
    'Getopt::Long' => '0',
    'HTML::FormFu::Model::DBIC' => '0.09000',
    'Path::Class' => '0',
    'Pod::Usage' => '0',
    'Test::More' => '0',
    'Test::Most' => '0',
    'parent' => '0',
    'rlib' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Catalyst-Model-FormFu',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Catalyst::Model::FormFu',
  'PREREQ_PM' => {
    'Catalyst::Component::InstancePerContext' => '0',
    'Catalyst::Model' => '0',
    'HTML::FormFu' => '0',
    'Moose' => '0',
    'Scalar::Util' => '0',
    'namespace::clean' => '0'
  },
  'VERSION' => '0.004',
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



