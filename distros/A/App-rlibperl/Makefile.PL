
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Execute perl prepending relative lib to \@INC",
  "AUTHOR" => "Randy Stauner <rwstauner\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Cwd" => 0,
    "Exporter" => 0,
    "File::Copy" => 0,
    "File::Find" => 0,
    "File::Path" => 0,
    "File::Temp" => 0,
    "Test::More" => "0.88"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-rlibperl",
  "EXE_FILES" => [
    "bin/rbinperl",
    "bin/rlibperl"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::rlibperl",
  "PREREQ_PM" => {
    "Config" => 0,
    "File::Spec::Functions" => 0,
    "FindBin" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.700",
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



