
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.17;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Generate CSS files from .less files",
  "AUTHOR" => "Michal Wojciechowski <odyniec\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.17"
  },
  "DISTNAME" => "Dancer-Plugin-Preprocess-Less",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dancer::Plugin::Preprocess::Less",
  "PREREQ_PM" => {
    "CSS::LESSp" => 0,
    "Cwd" => 0,
    "Dancer" => 0,
    "Dancer::Plugin" => 0,
    "File::Spec::Functions" => 0,
    "IPC::Open3" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Dancer::FileUtils" => 0,
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
    "TESTS" => "t/*.t t/paths/*.t"
  }
);


my %FallbackPrereqs = (
  "CSS::LESSp" => 0,
  "Cwd" => 0,
  "Dancer" => 0,
  "Dancer::FileUtils" => 0,
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



