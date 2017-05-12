
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
  "dist_abstract" => "application class for syntax highlighting Perl source code",
  "dist_author" => [
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "App-perlhl",
  "dist_version" => "0.007",
  "license" => "perl",
  "module_name" => "App::perlhl",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Getopt::Long" => 0,
    "Pod::Usage" => 0,
    "Syntax::Highlight::Perl::Improved" => "1.01",
    "Term::ANSIColor" => "3.00",
    "if" => 0,
    "perl" => "v5.10.1",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/perlhl"
  ],
  "test_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => 0,
    "Test::Output" => 0,
    "open" => 0
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
