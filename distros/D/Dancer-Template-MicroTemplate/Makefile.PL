
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Text::MicroTemplate engine for Dancer",
  "AUTHOR" => "James Aitken <jaitken\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Dancer" => 0,
    "Dancer::Test" => 0,
    "File::Spec" => 0,
    "File::Spec::Functions" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dancer-Template-MicroTemplate",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dancer::Template::MicroTemplate",
  "PREREQ_PM" => {
    "Dancer::Template::Abstract" => 0,
    "Text::MicroTemplate::File" => 0,
    "base" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.0.0",
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



