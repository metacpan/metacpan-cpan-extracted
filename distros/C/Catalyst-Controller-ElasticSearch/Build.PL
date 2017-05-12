
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
  "dist_abstract" => "Thin proxy for ElasticSearch with some protection",
  "dist_author" => [
    "Moritz Onken <onken\@netcubed.de>"
  ],
  "dist_name" => "Catalyst-Controller-ElasticSearch",
  "dist_version" => "0.1.0",
  "license" => "mit",
  "module_name" => "Catalyst::Controller::ElasticSearch",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Catalyst" => "5.9",
    "ElasticSearch" => "0.64",
    "List::MoreUtils" => "0.33",
    "MooseX::Attribute::Chained" => "v1.0.1"
  },
  "script_files" => [],
  "test_requires" => {
    "Catalyst::View::JSON" => 0,
    "HTTP::Request::Common" => 0,
    "Test::More" => "0.88"
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
