
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A container for functions for the git-gerrit program",
  "AUTHOR" => "Gustavo L. de M. Chaves <gnustavo\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-GitGerrit",
  "EXE_FILES" => [
    "bin/git-gerrit"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::GitGerrit",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "Gerrit::REST" => "0.009",
    "Getopt::Long" => 0,
    "Pod::Usage" => 0,
    "Text::Table" => 0,
    "URI" => 0,
    "URI::Escape" => 0,
    "locale" => 0,
    "open" => "1.07",
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0,
    "lib" => 0
  },
  "VERSION" => "0.022",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Dumper" => 0,
  "Exporter" => 0,
  "File::Spec" => 0,
  "File::Temp" => 0,
  "Gerrit::REST" => "0.009",
  "Getopt::Long" => 0,
  "Pod::Usage" => 0,
  "Test::More" => 0,
  "Text::Table" => 0,
  "URI" => 0,
  "URI::Escape" => 0,
  "lib" => 0,
  "locale" => 0,
  "open" => "1.07",
  "strict" => 0,
  "utf8" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



