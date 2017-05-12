
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
  "dist_abstract" => "Automagically inflates time columns into DateTime::Duration objects",
  "dist_author" => [
    "Robert Stone <drzigman\@cpan.org>"
  ],
  "dist_name" => "DBIx-Class-InflateColumn-Time",
  "dist_version" => "0.0.1",
  "license" => "perl",
  "module_name" => "DBIx::Class::InflateColumn::Time",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "DBIx::Class" => 0,
    "DateTime::Duration" => 0,
    "base" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.006"
  },
  "script_files" => [],
  "test_requires" => {
    "Data::Dumper" => 0,
    "DateTime" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0,
    "Test::Most" => 0
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
