
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Simple way to access Cassandra 0.7/0.8',
  'AUTHOR' => 'Gea-Suan Lin <gslin@gslin.org>',
  'BUILD_REQUIRES' => {
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30',
    'Module::Build' => '0.3601'
  },
  'DISTNAME' => 'Cassandra-Lite',
  'EXE_FILES' => [],
  'LICENSE' => 'bsd',
  'NAME' => 'Cassandra::Lite',
  'PREREQ_PM' => {
    'Any::Moose' => '0',
    'Class::Accessor' => '0',
    'Thrift' => '0',
    'Thrift::BinaryProtocol' => '0',
    'Thrift::FramedTransport' => '0',
    'Thrift::Socket' => '0',
    'constant' => '0'
  },
  'VERSION' => '0.4.0',
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



