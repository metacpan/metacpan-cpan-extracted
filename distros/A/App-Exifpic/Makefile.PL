
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Extract embedded jpegs from RAW files",
  "AUTHOR" => "Paul Fenwick <pjf\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Exifpic",
  "EXE_FILES" => [
    "bin/exifpic"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::Exifpic",
  "PREREQ_PM" => {
    "File::Slurp" => 0,
    "Image::ExifTool" => 0,
    "Imager" => 0,
    "Thread::Queue" => 0,
    "autodie" => 0,
    "constant" => 0,
    "strict" => 0,
    "threads" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.02",
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



