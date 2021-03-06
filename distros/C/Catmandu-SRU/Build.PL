
# This file was automatically generated by Dist::Zilla::Plugin::ModuleBuild v6.012.
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
  "dist_abstract" => "Catmandu module for working with SRU data",
  "dist_author" => [
    "Wouter Willaert, C<< <wouterw\@inuits.eu> >>"
  ],
  "dist_name" => "Catmandu-SRU",
  "dist_version" => "0.429",
  "license" => "perl",
  "module_name" => "Catmandu::SRU",
  "recursive_test_files" => 1,
  "requires" => {
    "Catmandu" => "1.20",
    "Catmandu::MODS" => "0.31",
    "Cpanel::JSON::XS" => "3.0213",
    "HTTP::Tiny" => "0.076",
    "Moo" => "1.005000",
    "URI::Escape" => "1.60",
    "XML::LibXML::Simple" => "0.91",
    "XML::LibXML::XPathContext" => 0,
    "XML::Struct" => "0.16",
    "YAML::XS" => "0.34",
    "namespace::clean" => 0,
    "perl" => "v5.10.1"
  },
  "test_requires" => {
    "Test::Exception" => 0,
    "Test::HTTP::LocalServer" => 0,
    "Test::More" => "1.001003",
    "Test::Pod" => 0,
    "Test::Simple" => "1.001003",
    "XML::XPath" => "1.13"
  }
);


my %fallback_build_requires = (
  "Module::Build" => "0.28",
  "Test::Exception" => 0,
  "Test::HTTP::LocalServer" => 0,
  "Test::More" => "1.001003",
  "Test::Pod" => 0,
  "Test::Simple" => "1.001003",
  "XML::XPath" => "1.13"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);


$build->create_build_script;
