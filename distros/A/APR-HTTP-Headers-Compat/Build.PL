use strict;
use warnings;

use lib 'inc';

use Module::Build;
use MyBuilder;

my $builder = MyBuilder->new(
  module_name          => 'APR::HTTP::Headers::Compat',
  license              => 'perl',
  dist_author          => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from    => 'lib/APR/HTTP/Headers/Compat.pm',
  recursive_test_files => 1,
  requires             => {
    'APR::Pool'     => 0,
    'APR::Table'    => 0,
    'HTTP::Headers' => 0,
    'Storable'      => 0,
    'Test::More'    => 0,
  },
  add_to_cleanup => ['APR-HTTP-Headers-Compat-*'],
);

$builder->create_build_script();
