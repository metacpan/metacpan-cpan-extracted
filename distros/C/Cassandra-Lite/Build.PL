
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.30',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Simple way to access Cassandra 0.7/0.8',
  'dist_author' => [
    'Gea-Suan Lin <gslin@gslin.org>'
  ],
  'dist_name' => 'Cassandra-Lite',
  'dist_version' => '0.4.0',
  'license' => 'bsd',
  'module_name' => 'Cassandra::Lite',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Any::Moose' => '0',
    'Class::Accessor' => '0',
    'Thrift' => '0',
    'Thrift::BinaryProtocol' => '0',
    'Thrift::FramedTransport' => '0',
    'Thrift::Socket' => '0',
    'constant' => '0',
    'perl' => '5.010'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
