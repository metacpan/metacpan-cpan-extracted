use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name    => 'Bundle::Net::SNMP::Mixin',
  dist_author    => 'Karl Gaissmaier <karl.gaissmaier (at) uni-ulm.de>',
  license        => 'perl',
  create_readme  => 1,
  add_to_cleanup => [qw/Bundle-Net-SNMP-Mixin-* Makefile* META.yml README/],
)->create_build_script();
