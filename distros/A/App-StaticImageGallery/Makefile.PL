
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Static Image Gallery',
  'AUTHOR' => 'Robert Bohne <rbo@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-StaticImageGallery',
  'EXE_FILES' => [
    'bin/sig'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::StaticImageGallery',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Class::MOP' => '0',
    'DateTime' => '0',
    'File::Basename' => '0',
    'File::Path' => '0',
    'Getopt::Lucid' => '0',
    'Imager' => '0',
    'MIME::Base64' => '0',
    'Path::Class' => '0',
    'Pod::Usage' => '0',
    'Template' => '0',
    'Template::Provider::FromDATA' => '0',
    'UNIVERSAL' => '0',
    'parent' => '0'
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



