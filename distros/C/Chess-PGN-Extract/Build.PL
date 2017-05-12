use 5.008_001;
use strict;
use Module::Build;
use Module::Build::Pluggable qw| CPANfile |;

my $build = Module::Build::Pluggable->new (
  module_name => 'Chess::PGN::Extract',
  license     => 'perl',

);

$build->create_build_script;
