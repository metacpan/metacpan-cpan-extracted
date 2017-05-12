use lib 'inc';
use Devel::AssertOS qw[-MSWin32];

use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "application class for managing a simple sysadmin log",
  "AUTHOR" => "Mike Doherty <doherty\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "App-Sysadmin-Log-Simple",
  "EXE_FILES" => [
    "bin/sysadmin-log"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::Sysadmin::Log::Simple",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Config::General" => 0,
    "DateTime" => 0,
    "DateTime::TimeZone" => 0,
    "File::Find::Rule" => 0,
    "File::HomeDir" => 0,
    "Getopt::Long" => 0,
    "HTTP::Tiny" => 0,
    "IO::Pager" => 0,
    "IO::Socket::INET" => 0,
    "Module::Pluggable" => 0,
    "Net::Twitter::Lite::WithAPIv1_1" => 0,
    "Path::Tiny" => 0,
    "Pod::Usage" => 0,
    "Try::Tiny" => 0,
    "URI::Escape" => 0,
    "autodie" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IO::Scalar" => 0,
    "IPC::Open3" => 0,
    "Path::Tiny" => "0.015",
    "Test::More" => "0.96",
    "Test::Output" => 0,
    "Test::Requires" => 0,
    "Test::Script" => "1.05"
  },
  "VERSION" => "0.009",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



