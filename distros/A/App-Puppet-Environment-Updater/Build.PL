
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Directory::Scratch" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::Class" => 0,
    "Test::Exception" => 0,
    "Test::More" => "0.88",
    "parent" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Update a Puppet environment in a Git branch",
  "dist_author" => [
    "Manfred Stock <mstock\@cpan.org>"
  ],
  "dist_name" => "App-Puppet-Environment-Updater",
  "dist_version" => "0.001001",
  "license" => "perl",
  "module_name" => "App::Puppet::Environment::Updater",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "File::pushd" => 0,
    "Git::Wrapper" => 0,
    "List::MoreUtils" => 0,
    "Log::Dispatchouli" => 0,
    "Moose" => 0,
    "MooseX::FollowPBP" => 0,
    "MooseX::Getopt" => 0,
    "MooseX::Types::Path::Class" => 0,
    "Path::Class::Dir" => 0,
    "Term::ANSIColor" => 0,
    "Try::Tiny" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/git-update-staging",
    "bin/git-update-testing",
    "bin/git-update-environment",
    "bin/git-update-production"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
