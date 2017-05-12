
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Catalyst view to HTML::Zoom',
  'AUTHOR' => 'Oliver Charles <oliver.g.charles@googlemail.com>',
  'BUILD_REQUIRES' => {
    'Catalyst::Action::RenderView' => '0.14',
    'Catalyst::Runtime' => '5.8',
    'Test::More' => '0.96'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Catalyst-View-HTML-Zoom',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Catalyst::View::HTML::Zoom',
  'PREREQ_PM' => {
    'Class::MOP' => '1.12',
    'HTML::Zoom' => '0.009',
    'Moose' => '1.21',
    'Path::Class' => '0.23',
    'namespace::autoclean' => '0.09'
  },
  'VERSION' => '0.003',
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



