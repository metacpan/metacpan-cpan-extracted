use Module::Build;

use strict;

my $build = Module::Build->new
  (
   module_name => 'Algorithm::Viterbi',
   license => 'perl',
   create_makefile_pl => 'pass_through',
  );

$build->create_build_script;
