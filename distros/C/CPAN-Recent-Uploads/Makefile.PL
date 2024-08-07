# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;

use 5.006000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Find the distributions recently uploaded to CPAN",
  "AUTHOR" => "Chris Williams <chris\@bingosnet.co.uk>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "CPAN-Recent-Uploads",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006000",
  "NAME" => "CPAN::Recent::Uploads",
  "PREREQ_PM" => {
    "Carp" => 0,
    "File::Spec" => 0,
    "File::Spec::Unix" => 0,
    "HTTP::Tiny" => "0.012",
    "URI" => "1.56",
    "YAML::XS" => "0.64"
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "HTTP::Daemon" => 0,
    "HTTP::Response" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0,
    "Test::RequiresInternet" => 0
  },
  "VERSION" => "0.16",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "File::Spec" => 0,
  "File::Spec::Unix" => 0,
  "HTTP::Daemon" => 0,
  "HTTP::Response" => 0,
  "HTTP::Tiny" => "0.012",
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Test::More" => 0,
  "Test::RequiresInternet" => 0,
  "URI" => "1.56",
  "YAML::XS" => "0.64"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
