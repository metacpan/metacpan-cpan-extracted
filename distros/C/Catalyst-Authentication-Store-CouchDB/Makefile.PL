
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A storage class for Catalyst Authentication using CouchDB',
  'AUTHOR' => 'Colin Bradford <cjbradford@gmail.com>',
  'BUILD_REQUIRES' => {
    'Catalyst' => '5.80032',
    'Catalyst::Controller' => '0',
    'Catalyst::Plugin::Authorization::Roles' => '0',
    'Catalyst::Plugin::Session' => '0',
    'Catalyst::Plugin::Session::State::Cookie' => '0',
    'Catalyst::Test' => '0',
    'English' => '0',
    'FindBin' => '1.49',
    'HTTP::Response' => '5.824',
    'LWP::UserAgent' => '5.834',
    'Test::Exception' => '0.31',
    'Test::More' => '0.98',
    'Test::WWW::Mechanize::Catalyst' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Catalyst-Authentication-Store-CouchDB',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Catalyst::Authentication::Store::CouchDB',
  'PREREQ_PM' => {
    'Catalyst::Authentication::User' => '0',
    'Catalyst::Exception' => '0',
    'Catalyst::Utils' => '0',
    'CouchDB::Client' => '0.09',
    'JSON' => '2.17',
    'Moose' => '2.00',
    'MooseX::NonMoose' => '0.20',
    'Try::Tiny' => '0.09',
    'namespace::autoclean' => '0'
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



