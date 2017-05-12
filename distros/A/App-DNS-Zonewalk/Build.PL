use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name       => 'App::DNS::Zonewalk',
  license           => 'perl',
  dist_author       => q{Karl Gaissmaier <gaissmai(at)cpan.org>},
  dist_version_from => 'bin/zonewalk',
  create_readme     => 1,
  build_requires    => { 'Test::More' => 0, },
  script_files      => [qw( bin/zonewalk)],
  requires          => {
    'perl'     => '5.10.0',
    'parent'   => 0,
    'Net::DNS' => 0,
  },
  add_to_cleanup     => ['App-DNS-Zonewalk-*', 'MANIFEST.bak'],
  create_makefile_pl => 'small',
);

$builder->create_build_script();
