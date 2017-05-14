
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Mojo::Template wrapper for Dancer2',
  'AUTHOR' => 'Nikita Melikgov <ver@0xff.su>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Dancer2-Template-MojoTemplate',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Dancer2::Template::MojoTemplate',
  'PREREQ_PM' => {
    'Dancer2::Core::Role::Template' => '0',
    'Dancer2::Core::Types' => '0',
    'Mojo::Template' => '0',
    'Moo' => '0',
    'Carp' => '0',
  },
  'VERSION' => '0.1.1',
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



