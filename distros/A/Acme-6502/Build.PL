use strict;
use warnings;

use lib 'inc';

use Module::Build;
use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'Acme::6502',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/Acme/6502.pm',
  requires          => {
    'Test::More'      => 0,
    'version'         => 0,
    'Term::ReadKey'   => 0,
  },
  add_to_cleanup => ['Acme-6502-*'],
);

$builder->create_build_script();
