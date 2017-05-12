
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'DEPRECATED: Browser Detection',
  'AUTHOR' => 'Christian Hansen <ch@ngmedia.com>, Marcus Ramberg <mramberg@cpan.org>, Florian Ragwitz <rafl@debian.org>',
  'BUILD_REQUIRES' => {
    'Catalyst' => '0',
    'Catalyst::Controller' => '0',
    'Catalyst::Test' => '0',
    'FindBin' => '0',
    'Moose' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Catalyst-Plugin-Browser',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Catalyst::Plugin::Browser',
  'PREREQ_PM' => {
    'Catalyst::Runtime' => '5.80004',
    'Catalyst::TraitFor::Request::BrowserDetect' => '0',
    'CatalystX::RoleApplicator' => '0',
    'Moose::Role' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '0.08',
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



