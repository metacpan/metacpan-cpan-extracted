
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Class::Accessor::Classy',
  license             => 'perl',
  requires => {
    'Module::Build'   => 0.28,
    'version'         => 0,
    'Test::More'      => 0,
  },
  add_to_cleanup      => [ qw(Class-Accessor-Classy-* META.yml)],
  #create_makefile_pl => 'small',
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
