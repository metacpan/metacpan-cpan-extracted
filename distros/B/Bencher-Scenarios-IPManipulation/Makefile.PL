# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.008.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Benchmark modules that do IP address manipulation",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Bencher-Scenarios-IPManipulation",
  "LICENSE" => "perl",
  "NAME" => "Bencher::Scenarios::IPManipulation",
  "PREREQ_PM" => {
    "Net::CIDR" => 0,
    "NetAddr::IP" => 0,
    "NetObj::IPv4Address" => 0
  },
  "TEST_REQUIRES" => {
    "Bencher::Backend" => "1.034",
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Bencher::Backend" => "1.034",
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Net::CIDR" => 0,
  "NetAddr::IP" => 0,
  "NetObj::IPv4Address" => 0,
  "Test::More" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
