# This Makefile.PL for Cache-Profile was generated by
# Dist::Zilla::Plugin::MakeMaker::Awesome 0.38.
# Don't edit it but the dist.ini and plugins used to construct it.

use strict;
use warnings;

use 5.006;
use ExtUtils::MakeMaker;

foreach my $sub (qw(tv_interval gettimeofday time clock)) {
  eval { require Time::HiRes; Time::HiRes->import($sub) };
  if ($@ and $@ =~ /Time::HiRes::.*: unimplemented in this platform/) {
    print $@;
    die 'OS unsupported';
  }
}

my %WriteMakefileArgs = (
  "ABSTRACT" => "Measure the performance of a cache",
  "AUTHOR" => "\x{5d9}\x{5d5}\x{5d1}\x{5dc} \x{5e7}\x{5d5}\x{5d2}'\x{5de}\x{5df} (Yuval Kogman) <nothingmuch\@woobling.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Cache-Profile",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Cache::Profile",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::MOP" => 0,
    "Guard" => 0,
    "Moose" => 0,
    "Time::HiRes" => "1.84",
    "Try::Tiny" => 0,
    "namespace::autoclean" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "List::Util" => 0,
    "Test::More" => 0,
    "Test::Needs" => 0,
    "ok" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.06",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "Carp" => 0,
  "Class::MOP" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Guard" => 0,
  "List::Util" => 0,
  "Moose" => 0,
  "Test::More" => 0,
  "Test::Needs" => 0,
  "Time::HiRes" => "1.84",
  "Try::Tiny" => 0,
  "namespace::autoclean" => 0,
  "ok" => 0,
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
