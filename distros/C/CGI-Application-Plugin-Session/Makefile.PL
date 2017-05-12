
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Plugin that adds session support to CGI::Application",
  "AUTHOR" => "Cees Hek <ceeshek\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CGI-Application-Plugin-Session",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "CGI::Application::Plugin::Session",
  "PREREQ_PM" => {
    "CGI::Application" => "3.21",
    "CGI::Session" => "4.48",
    "File::Spec" => 0,
    "Scalar::Util" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => "1.001002"
  },
  "VERSION" => "1.05",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "CGI::Application" => "3.21",
  "CGI::Session" => "4.48",
  "File::Spec" => 0,
  "Scalar::Util" => 0,
  "Test::More" => "1.001002"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



