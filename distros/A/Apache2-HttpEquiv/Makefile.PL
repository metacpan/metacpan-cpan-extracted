
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Convert <meta http-equiv=...> to HTTP headers",
  "AUTHOR" => "Christopher J. Madsen <perl\@cjmweb.net>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Apache2-HttpEquiv",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Apache2::HttpEquiv",
  "PREREQ_PM" => {
    "Apache2::Const" => 0,
    "HTML::PullParser" => 0
  },
  "TEST_REQUIRES" => {
    "File::Temp" => 0,
    "Moo" => 0,
    "Test::More" => "0.88"
  },
  "VERSION" => "1.00",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Apache2::Const" => 0,
  "File::Temp" => 0,
  "HTML::PullParser" => 0,
  "Moo" => 0,
  "Test::More" => "0.88"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



