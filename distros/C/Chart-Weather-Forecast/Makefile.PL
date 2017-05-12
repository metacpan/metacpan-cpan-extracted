
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Weather Forecast Charts',
  'AUTHOR' => 'Mateu X Hunter <hunter@missoula.org>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'Test::More' => '0',
    'Try::Tiny' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Chart-Weather-Forecast',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Chart::Weather::Forecast',
  'PREREQ_PM' => {
    'Chart::Clicker' => '0',
    'Chart::Clicker::Data::DataSet' => '0',
    'Chart::Clicker::Data::Range' => '0',
    'Chart::Clicker::Data::Series' => '0',
    'Chart::Clicker::Drawing::ColorAllocator' => '0',
    'Data::Dumper::Concise' => '0',
    'Geometry::Primitive::Circle' => '0',
    'Graphics::Color::RGB' => '0',
    'Graphics::Primitive::Font' => '0',
    'List::Util' => '0',
    'Moose' => '0',
    'MooseX::Types::Path::Class' => '0',
    'Number::Format' => '0',
    'Path::Class' => '0',
    'namespace::autoclean' => '0',
    'strictures' => '1'
  },
  'VERSION' => '0.04',
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



