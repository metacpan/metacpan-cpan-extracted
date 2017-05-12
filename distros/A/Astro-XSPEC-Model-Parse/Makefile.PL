
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'parse an XSPEC model.dat file',
  'AUTHOR' => 'Diab Jerius <djerius@cpan.org>',
  'BUILD_REQUIRES' => {
    'Data::Dumper' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Scalar::Util' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0.94',
    'perl' => '5.004'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Astro-XSPEC-Model-Parse',
  'EXE_FILES' => [],
  'LICENSE' => 'gpl',
  'NAME' => 'Astro::XSPEC::Model::Parse',
  'PREREQ_PM' => {
    'Carp' => '0',
    'IO::File' => '0',
    'Params::Validate' => '0',
    'Text::ParseWords' => '0'
  },
  'VERSION' => '0.01',
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



