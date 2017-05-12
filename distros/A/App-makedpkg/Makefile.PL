
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Facilitate building Debian packages with templates",
  "AUTHOR" => "Jakob Vo\x{df}",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "App-makedpkg",
  "EXE_FILES" => [
    "bin/makedpkg"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::makedpkg",
  "PREREQ_PM" => {
    "App::Cmd" => "0.323",
    "Config::Any" => "0.24",
    "File::ShareDir" => "1.0",
    "Text::Template" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.05",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "App::Cmd" => "0.323",
  "Config::Any" => "0.24",
  "File::ShareDir" => "1.0",
  "Text::Template" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


