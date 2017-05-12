
use strict;
use warnings;

use 5.012;

use ExtUtils::MakeMaker 6.72;



my %WriteMakefileArgs = (
  "ABSTRACT" => "JSON pointer-like and Perl union for flexible perlish structures validation",
  "AUTHOR" => "Ivan Baidakou <dmol\@gmx.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.72"
  },
  "DISTNAME" => "Data-DynamicValidator",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::DynamicValidator",
  "PREREQ_PM" => {
    "Devel::LexAlias" => "0.05",
    "Eval::Closure" => "0.11",
    "List::MoreUtils" => "0.33",
    "PadWalker" => "1.98",
    "Try::Tiny" => "0.18",
    "aliased" => "0.31"
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "File::Temp" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.98",
    "Test::Warnings" => "0.013"
  },
  "VERSION" => "0.03",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Devel::LexAlias" => "0.05",
  "Eval::Closure" => "0.11",
  "File::Spec" => 0,
  "File::Temp" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "List::MoreUtils" => "0.33",
  "PadWalker" => "1.98",
  "Test::More" => "0.98",
  "Test::Warnings" => "0.013",
  "Try::Tiny" => "0.18",
  "aliased" => "0.31"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



