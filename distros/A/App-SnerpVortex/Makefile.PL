
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Replay a Subversion dump into Git/Filesystem/etc.',
  'AUTHOR' => 'Rocco Caputo <rcaputo@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-SnerpVortex',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'App::SnerpVortex',
  'PREREQ_PM' => {
    'DBD::SQLite' => '1.29',
    'DBI' => '1.613',
    'Digest::MD5' => '2.36',
    'File::Copy' => '2.11',
    'File::Path' => '2.04',
    'Moose' => '1.10',
    'SVN::Dump' => '0.04',
    'Storable' => '2.18'
  },
  'VERSION' => '1.000',
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



