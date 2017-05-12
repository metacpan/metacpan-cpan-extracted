
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.17;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Check a password against a list of common passwords",
  "AUTHOR" => "David Golden <dagolden\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.17",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Data-Password-Common",
  "EXE_FILES" => [],
  "LICENSE" => "apache",
  "NAME" => "Data::Password::Common",
  "PREREQ_PM" => {
    "File::ShareDir" => 0,
    "IO::File" => 0,
    "Search::Dict" => 0,
    "Sub::Exporter" => 0,
    "autodie" => "2.00",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec::Functions" => 0,
    "List::Util" => 0,
    "Test::File::ShareDir" => 0,
    "Test::More" => "0.96",
    "utf8" => 0
  },
  "VERSION" => "0.004",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "ExtUtils::MakeMaker" => 0,
  "File::ShareDir" => 0,
  "File::Spec::Functions" => 0,
  "IO::File" => 0,
  "List::Util" => 0,
  "Search::Dict" => 0,
  "Sub::Exporter" => 0,
  "Test::File::ShareDir" => 0,
  "Test::More" => "0.96",
  "autodie" => "2.00",
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

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


