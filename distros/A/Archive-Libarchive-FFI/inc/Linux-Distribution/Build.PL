use strict;
use Module::Build;
#created by eumm-migrate.pl

unless (lc $^O eq "linux") {
    die "OS unsupported\n";
}

my $build = Module::Build->new(
  'auto_configure_requires' => 0,
  'dist_author' => 'Alexandr Ciornii <alexchorny@gmail.com>',
  'module_name' => 'Linux::Distribution',
  'meta_merge' => {
    'resources' => {
      'repository' => 'https://github.com/chorny/Linux-Distribution'
    }
  },
  'requires' => {
    'perl' => '5.006',
  },
  'build_requires' => {
    'Test::More' => 0,
  },
  'license' => 'perl',
  'dist_version_from' => 'lib/Linux/Distribution.pm'
);

$build->create_build_script();
