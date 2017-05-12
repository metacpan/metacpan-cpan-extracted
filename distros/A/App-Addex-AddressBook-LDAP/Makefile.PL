
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'LDAP address book for App::Addex',
  'AUTHOR' => 'Maximilian Gass <mxey@ghosthacking.net>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-Addex-AddressBook-LDAP',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'App::Addex::AddressBook::LDAP',
  'PREREQ_PM' => {
    'App::Addex::AddressBook' => '0',
    'App::Addex::Entry' => '0',
    'App::Addex::Entry::EmailAddress' => '0',
    'Carp' => '0',
    'Modern::Perl' => '0',
    'Net::LDAP' => '0',
    'URI' => '0',
    'parent' => '0'
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



