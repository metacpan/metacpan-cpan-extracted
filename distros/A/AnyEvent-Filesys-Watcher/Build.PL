
# This file was automatically generated by Dist::Zilla::Plugin::ModuleBuild v6.032.
use strict;
use warnings;

use Module::Build 0.28;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.28"
  },
  "configure_requires" => {
    "Module::Build" => "0.28"
  },
  "dist_abstract" => "Watch file system for changes",
  "dist_author" => [
    "Guido Flohr <guido.flohr\@cantanea.com>"
  ],
  "dist_name" => "AnyEvent-Filesys-Watcher",
  "dist_version" => "v0.1.1",
  "license" => "unrestricted",
  "module_name" => "AnyEvent::Filesys::Watcher",
  "recursive_test_files" => 1,
  "requires" => {
    "AnyEvent" => 0,
    "Carp" => 0,
    "Cwd" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IO::Select" => 0,
    "Locale::TextDomain" => 0,
    "Path::Iterator::Rule" => 0,
    "Scalar::Util" => 0,
    "Socket" => 0,
    "Time::HiRes" => 0,
    "base" => 0,
    "constant" => 0,
    "perl" => "5.008",
    "strict" => 0
  },
  "test_requires" => {
    "Data::Dump" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "File::Find" => 0,
    "File::Path" => 0,
    "File::Temp" => 0,
    "Test::Exception" => "0.43",
    "Test::Memory::Cycle" => 0,
    "Test::More" => 0,
    "Test::Without::Module" => "0.21",
    "autodie" => 0,
    "lib" => 0,
    "warnings" => 0
  }
);


my %fallback_build_requires = (
  "Data::Dump" => 0,
  "Exporter" => 0,
  "File::Basename" => 0,
  "File::Copy" => 0,
  "File::Find" => 0,
  "File::Path" => 0,
  "File::Temp" => 0,
  "Module::Build" => "0.28",
  "Test::Exception" => "0.43",
  "Test::Memory::Cycle" => 0,
  "Test::More" => 0,
  "Test::Without::Module" => "0.21",
  "autodie" => 0,
  "lib" => 0,
  "warnings" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

if ( $^O eq 'linux' ) {
	$module_build_args{requires}{'Linux::Inotify2'} = '1.22';
}

if ( $^O eq 'darwin' ) {
	$module_build_args{requires}{'Mac::FSEvents'} = '0.20';
}

if ( $^O =~ /bsd/i ) {
	$module_build_args{requires}{'BSD::Resource'} = '1.2911';
	$module_build_args{requires}{'IO::KQueue'} = '0.34';
}

if ( $^O eq 'MSWin32' ) {
	$module_build_args{requires}{'Filesys::Notify::Win32::ReadDirectoryChanges'} = '0.04';
	$module_build_args{requires}{'Thread::Queue'} = '3.13';
}

if ( $^O eq 'cygwin' ) {
	$module_build_args{requires}{'Filesys::Notify::Win32::ReadDirectoryChanges'} = '0.04';
	$module_build_args{requires}{'Thread::Queue'} = '3.13';
}

my $build = Module::Build->new(%module_build_args);


$build->create_build_script;
