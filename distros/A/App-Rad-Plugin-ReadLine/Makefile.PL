
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'App::Rad::Plugin::ReadLine a Term::UI ->shell for Rad Apps',
  'AUTHOR' => 'FOOLISH <FOOLISH@cpan.org>',
  'BUILD_REQUIRES' => {
    'App::Rad' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-Rad-Plugin-ReadLine',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'App::Rad::Plugin::ReadLine',
  'PREREQ_PM' => {
    'Data::Dumper' => '0',
    'Term::ReadLine' => '0',
    'Term::UI' => '0'
  },
  'VERSION' => '0.002',
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



