use 5.006;
use warnings;
use strict;

use FindBin qw($Bin);
use File::Spec;
use lib File::Spec->catdir($Bin, 'inc');

use Module::Build::AstroNova;

Module::Build::AstroNova->new(
  module_name => "Astro::Nova",
  all_from => 'lib/Astro/Nova.pm',
  license => "perl",
  dist_author => 'Steffen Mueller <smueller@cpan.org>',
  configure_requires => {
    "Module::Build" => 0,
    "File::Spec" => 0,
    "lib" => 0,
    "FindBin" => 0,
  },
  build_requires => {
    "ExtUtils::CBuilder" => "0.15",
    "ExtUtils::ParseXS" => "3.05",
    "Module::Build" => 0,
    "Test::More" => 0,
    "Cwd" => 0,
  },
  requires => {
    "Carp" => 0,
    "File::Spec" => 0,
    "Exporter" => 0,
    "XSLoader" => 0,
  },
  dynamic_config => 0,
  meta_add => { distribution_type => "module" },
  add_to_cleanup => [ qw(XS/Structs.xs) ],
  create_readme => 1,
  include_dirs => ['.', File::Spec->catdir($Module::Build::AstroNova::NovaDir, 'src')],
  extra_linker_flags => [$Module::Build::AstroNova::NovaDirStaticLib],
)->create_build_script;

exit 0;

