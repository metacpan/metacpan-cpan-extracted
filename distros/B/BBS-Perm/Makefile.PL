
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'a BBS client based on vte',
  'AUTHOR' => 'sunnavy <sunnavy@gmail.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'BBS-Perm',
  'EXE_FILES' => [
    'bin/bbs-perm',
    'bin/bbs-perm-config',
    'bin/bbs-perm-agent'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'BBS::Perm',
  'PREREQ_PM' => {
    'Expect' => '0',
    'File::Slurp' => '0',
    'File::Which' => '0',
    'Gnome2::Vte' => '0',
    'IO::Pty' => '0',
    'IO::Stty' => '0',
    'IP::QQWry' => '0',
    'Regexp::Common' => '0',
    'UNIVERSAL::moniker' => '0',
    'YAML::Syck' => '0'
  },
  'VERSION' => '1.01',
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



