
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Simple authentication to Atheme IRC services',
  'AUTHOR' => 'Alexandria Marie Wolcott <alyx@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Authen-Simple-Atheme',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Authen::Simple::Atheme',
  'PREREQ_PM' => {
    'Atheme' => '0',
    'Authen::Simple::Adapter' => '0',
    'Params::Validate' => '0'
  },
  'VERSION' => '0.003',
  'test' => {
    'TESTS' => ''
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



