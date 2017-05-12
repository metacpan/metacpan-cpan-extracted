
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.17;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Generate HTML content from Markdown files",
  "AUTHOR" => "Michal Wojciechowski <odyniec\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.17"
  },
  "DISTNAME" => "Dancer-Plugin-Preprocess-Markdown",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dancer::Plugin::Preprocess::Markdown",
  "PREREQ_PM" => {
    "Cwd" => 0,
    "Dancer" => 0,
    "Dancer::Plugin" => 0,
    "File::Spec::Functions" => 0,
    "Text::Markdown" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Dancer::Test" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "List::Util" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.021",
  "test" => {
    "TESTS" => "t/*.t t/10_settings/01_layout/*.t"
  }
);


my %FallbackPrereqs = (
  "Cwd" => 0,
  "Dancer" => 0,
  "Dancer::Plugin" => 0,
  "Dancer::Test" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "File::Spec::Functions" => 0,
  "File::Temp" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "List::Util" => 0,
  "Test::More" => 0,
  "Text::Markdown" => 0,
  "strict" => 0,
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



