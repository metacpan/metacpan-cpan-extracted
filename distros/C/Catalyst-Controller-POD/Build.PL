
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Catalyst' => '0',
    'Catalyst::Runtime' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0.88',
    'Test::WWW::Mechanize::Catalyst' => '0',
    'parent' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Serves PODs right from your Catalyst application',
  'dist_author' => [
    'Moritz Onken'
  ],
  'dist_name' => 'Catalyst-Controller-POD',
  'dist_version' => '1.0.0',
  'license' => 'bsd',
  'module_name' => 'Catalyst::Controller::POD',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Catalyst::Controller' => '0',
    'Catalyst::Plugin::Static::Simple' => '0',
    'Class::Accessor::Fast' => '0.31',
    'File::Find' => '0.05',
    'File::ShareDir' => '0.05',
    'File::Slurp' => '9999',
    'File::Spec' => '0',
    'JSON::XS' => '2.21',
    'LWP::Simple' => '5.810',
    'List::MoreUtils' => '0.22',
    'Path::Class::File' => '0',
    'Pod::POM' => '0.17',
    'Pod::POM::View::HTML' => '0',
    'Pod::POM::View::TOC' => '0.02',
    'Pod::Simple' => '3.05',
    'Pod::Simple::Search' => '0',
    'Test::More' => '0.42',
    'Test::WWW::Mechanize::Catalyst' => '0.41',
    'XML::Simple' => '2.18',
    'parent' => '0',
    'utf8' => '0'
  },
  'script_files' => [],
  'share_dir' => {
    'dist' => 'share'
  }
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
