
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'RDF view for your data',
  'AUTHOR' => 'Thiago Rondon <thiago@aware.com.br>',
  'BUILD_REQUIRES' => {
    'Catalyst' => '0',
    'Catalyst::Controller' => '0',
    'Catalyst::Test' => '0',
    'Encode' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'FindBin' => '0',
    'HTTP::Request::AsCGI' => '0',
    'MRO::Compat' => '0',
    'RDF::Simple::Parser' => '0',
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Catalyst-View-RDF',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Catalyst::View::RDF',
  'PREREQ_PM' => {
    'Catalyst::View' => '0',
    'Moose' => '0',
    'RDF::Simple::Serialiser' => '0'
  },
  'VERSION' => '0.01',
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



