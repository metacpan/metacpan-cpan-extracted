
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "build a bogus CPAN instance for testing",
  "AUTHOR" => "Ricardo Signes <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CPAN-Faker",
  "EXE_FILES" => [
    "bin/cpanfaker"
  ],
  "LICENSE" => "perl",
  "NAME" => "CPAN::Faker",
  "PREREQ_PM" => {
    "CPAN::Checksums" => 0,
    "Compress::Zlib" => 0,
    "Cwd" => 0,
    "Data::Section" => 0,
    "File::Find" => 0,
    "File::Next" => 0,
    "File::Path" => 0,
    "File::Spec" => 0,
    "Getopt::Long::Descriptive" => 0,
    "IO::Compress::Gzip" => 0,
    "Module::Faker::Dist" => "0.015",
    "Moose" => 0,
    "Sort::Versions" => 0,
    "Text::Template" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Temp" => 0,
    "Test::More" => "0.96"
  },
  "VERSION" => "0.010",
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



