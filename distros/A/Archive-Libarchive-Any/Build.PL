BEGIN {
  use strict; use warnings;
  unless(eval q{ use 5.008; 1}) {
    print "Perl 5.008 or better required\n";
    exit;
  }
}

# This file was automatically generated by Dist::Zilla::Plugin::ModuleBuild v6.017.
use strict;
use warnings;

use Module::Build 0.28;
use lib qw{inc}; use My::ModuleBuild;

my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.28"
  },
  "configure_requires" => {
    "Module::Build" => "0.28"
  },
  "dist_abstract" => "Perl bindings to libarchive",
  "dist_author" => [
    "Graham Ollis <plicease\@cpan.org>"
  ],
  "dist_name" => "Archive-Libarchive-Any",
  "dist_version" => "0.0901",
  "license" => "perl",
  "module_name" => "Archive::Libarchive::Any",
  "recursive_test_files" => 1,
  "requires" => {
    "perl" => "5.008"
  },
  "test_requires" => {
    "File::Basename" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Test::More" => "0.98",
    "open" => 0,
    "utf8" => 0
  }
);


my %fallback_build_requires = (
  "File::Basename" => 0,
  "File::Spec" => 0,
  "File::Temp" => 0,
  "FindBin" => 0,
  "Module::Build" => "0.28",
  "Test::More" => "0.98",
  "open" => 0,
  "utf8" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = My::ModuleBuild->new(%module_build_args);


$build->create_build_script;
