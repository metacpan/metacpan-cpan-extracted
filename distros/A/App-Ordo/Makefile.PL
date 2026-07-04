use strict;
use warnings;

use 5.008004;

use ExtUtils::MakeMaker;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "A utility module for the ordo script",
  "AUTHOR" => "Nathaniel Graham <ngraham\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::ShareDir::Install" => "0.06"
  },
  "DISTNAME" => "App-Ordo",
  "EXE_FILES" => [
    "script/ordo"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008004",
  "NAME" => "App::Ordo",
  "PREREQ_PM" => {
    "Date::Parse" => 0,
    "DateTime::TimeZone" => 0,
    "Email::Valid" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "File::Path" => 0,
    "File::ShareDir" => 0,
    "File::Spec" => 0,
    "Getopt::Long" => 0,
    "IO::Socket::INET" => 0,
    "JSON" => 0,
    "Mojo::UserAgent" => 0,
    "POSIX" => 0,
    "Term::ANSIColor" => 0,
    "Term::ReadKey" => 0,
    "Term::ReadLine::Perl5" => 0,
    "Text::Table::Tiny" => "1.02",
    "Time::Local" => 0,
    "feature" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.06",
  "test" => {
    "TESTS" => ""
  }
);


my %FallbackPrereqs = (
  "Date::Parse" => 0,
  "DateTime::TimeZone" => 0,
  "Email::Valid" => 0,
  "Exporter" => 0,
  "File::Basename" => 0,
  "File::Copy" => 0,
  "File::Path" => 0,
  "File::ShareDir" => 0,
  "File::Spec" => 0,
  "Getopt::Long" => 0,
  "IO::Socket::INET" => 0,
  "JSON" => 0,
  "Mojo::UserAgent" => 0,
  "POSIX" => 0,
  "Term::ANSIColor" => 0,
  "Term::ReadKey" => 0,
  "Term::ReadLine::Perl5" => 0,
  "Text::Table::Tiny" => "1.02",
  "Time::Local" => 0,
  "feature" => 0,
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

{
package
MY;
use File::ShareDir::Install qw(postamble);
}
