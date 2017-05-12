
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "App::WIoZ create a SVG or PNG image of a word cloud from a simple text file",
  "AUTHOR" => "Yves Agostini <yvesago\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-WIoZ",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "App::WIoZ",
  "PREREQ_PM" => {
    "Cairo" => 0,
    "Color::Mix" => 0,
    "Graphics::ColorNames" => 0,
    "Math::PlanePath::HilbertCurve" => 0,
    "Moose" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.004",
  "test" => {
    "TESTS" => "t/*.t"
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



