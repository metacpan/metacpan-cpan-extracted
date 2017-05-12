use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
   module_name       => 'Data::HexDump::XXD',
   license           => 'perl',
   dist_author       => 'Flavio Poletti <flavio [at] polettix [dot] it>',
   dist_version_from => 'VERSION',
   requires          => {
      'Test::More' => 0,
      'version'    => 0,
   },
   add_to_cleanup => ['Data-HexDump-XXD-*'],
);

$builder->create_build_script();
