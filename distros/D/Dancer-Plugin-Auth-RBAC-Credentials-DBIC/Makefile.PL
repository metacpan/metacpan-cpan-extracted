
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Dancer::Plugin::Auth::RBAC authentication via DBIx::Class',
  'AUTHOR' => 'Dagfinn Ilmari Mannsåker <ilmari@photobox.com>',
  'BUILD_REQUIRES' => {
    'DBIx::Class::Core' => '0',
    'DBIx::Class::Schema' => '0',
    'File::Temp' => '0',
    'SQL::Translator' => '0.11006',
    'Test::More' => '0',
    'ok' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Dancer-Plugin-Auth-RBAC-Credentials-DBIC',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Dancer::Plugin::Auth::RBAC::Credentials::DBIC',
  'PREREQ_PM' => {
    'Dancer::Plugin::Auth::RBAC::Credentials' => '0',
    'Dancer::Plugin::DBIC' => '0.15',
    'parent' => '0'
  },
  'VERSION' => '0.003',
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



