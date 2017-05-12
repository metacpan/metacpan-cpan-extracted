
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'CPAN GUI in Gtk2',
  'AUTHOR' => 'Sawyer X <xsawyerx@cpan.org>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'DISTNAME' => 'App-cpang',
  'EXE_FILES' => [
    'bin/cpang'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::cpang',
  'PREREQ_PM' => {
    'Glib' => '0',
    'Gnome2::Vte' => '0',
    'Gtk2' => '0'
  },
  'VERSION' => '0.03',
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



