
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Minify your served CSS files",
  "AUTHOR" => "Ivan Drinchev <drinchev (at) gmail (dot) com>, Arthur Axel \"fREW\" Schmidt <frioux\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-View-CSS-Minifier-XS",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::View::CSS::Minifier::XS",
  "PREREQ_PM" => {
    "CSS::Minifier::XS" => 0,
    "Catalyst" => "5.64",
    "Catalyst::Test" => 0,
    "File::Spec" => 0,
    "FindBin" => 0,
    "HTTP::Headers" => 0,
    "HTTP::Request" => 0,
    "Moose" => 0,
    "MooseX::Aliases" => 0,
    "Path::Class::Dir" => "0.17",
    "Test::More" => "0.88",
    "URI" => 0,
    "autodie" => 0,
    "parent" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "2.000002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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



