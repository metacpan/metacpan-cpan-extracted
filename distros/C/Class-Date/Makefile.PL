use lib 'inc';
use Devel::AssertOS qw[-Win32];
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.011.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Class for easy date and time manipulation",
  "AUTHOR" => "dLux (Szab\x{f3}, Bal\x{e1}zs) <dlux\@dlux.hu>, Gabor Szabo <szabgab\@gmail.com>, Yanick Champoux <yanick\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Class-Date",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Class::Date",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Date::Parse" => 0,
    "Exporter" => 0,
    "POSIX" => 0,
    "Scalar::Util" => 0,
    "Time::Local" => 0,
    "constant" => 0,
    "overload" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0,
    "Test::Warnings" => 0
  },
  "VERSION" => "1.1.17",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Date::Parse" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "POSIX" => 0,
  "Scalar::Util" => 0,
  "Test::More" => 0,
  "Test::Warnings" => 0,
  "Time::Local" => 0,
  "constant" => 0,
  "overload" => 0,
  "strict" => 0,
  "vars" => 0,
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
