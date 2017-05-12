
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'mass upload of files via SCP/FTP/...',
  'AUTHOR' => 'Torsten Raudssus <torsten@raudssus.de>, Apocalypse <APOCAL@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.96'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'App-Shotgun',
  'EXE_FILES' => [
    'bin/shotgun'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::Shotgun',
  'PREREQ_PM' => {
    'Cwd' => '3.33',
    'Expect' => '1.21',
    'Moose' => '2.0007',
    'MooseX::Getopt' => '0.37',
    'MooseX::LogDispatch' => '1.2002',
    'MooseX::POE::SweetArgs' => '0.213',
    'MooseX::Types::Path::Class' => '0.05',
    'Net::SFTP::Foreign' => '1.64',
    'POE::Component::Client::SimpleFTP' => '0.003',
    'POE::Component::Generic' => '0.1205',
    'Path::Class::Dir' => '0.23'
  },
  'VERSION' => '0.001',
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



