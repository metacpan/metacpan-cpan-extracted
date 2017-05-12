
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Layers for DocumentRoot',
  'AUTHOR' => 'Alex J. G. Burzyński <ajgb@cpan.org>',
  'BUILD_REQUIRES' => {
    'Module::Build' => '0.3601',
    'Test::Httpd::Apache2' => '0.08',
    'Test::NoWarnings' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'DISTNAME' => 'Apache2-Layer',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Apache2::Layer',
  'PREREQ_PM' => {
    'File::Spec' => '3.31',
    'LWP::UserAgent' => '5.835',
    'mod_perl2' => '2.000004'
  },
  'VERSION' => '1.103360',
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



