use lib 'inc';
use Devel::AssertOS qw[-MSWin32];

use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "application class for managing a simple sysadmin log",
  "dist_author" => [
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "App-Sysadmin-Log-Simple",
  "dist_version" => "0.009",
  "license" => "perl",
  "module_name" => "App::Sysadmin::Log::Simple",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
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
    "perl" => "v5.10.1",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/sysadmin-log"
  ],
  "test_requires" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IO::Scalar" => 0,
    "IPC::Open3" => 0,
    "Path::Tiny" => "0.015",
    "Test::More" => "0.96",
    "Test::Output" => 0,
    "Test::Requires" => 0,
    "Test::Script" => "1.05"
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
