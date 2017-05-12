
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Preview POD files in a browser',
  'AUTHOR' => 'Peter Shangov <pshangov@yahoo.com>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-PodPreview',
  'EXE_FILES' => [
    'bin/podpreview'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::PodPreview',
  'PREREQ_PM' => {
    'Browser::Open' => '0',
    'Carp' => '0',
    'Config::Tiny' => '0',
    'File::HomeDir' => '0',
    'File::Spec' => '0',
    'File::Temp' => '0',
    'Perl6::Export::Attrs' => '0',
    'Pod::Simple::HTML' => '0',
    'Pod::Usage::CommandLine' => '0',
    'autodie' => '0'
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



