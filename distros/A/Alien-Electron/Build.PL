use strict;

use lib q(.);
use ElectronModuleBuild;

my $build = ElectronModuleBuild->new(
  module_name => 'Alien::Electron',
  dist_abstract => 'Download and install the electron GUI framework',
  dist_author => 'Doug Hoyte <doug@hcsw.org>',
  license => 'perl',
  configure_requires => {
    'Module::Build' => 0,
  },
  build_requires => {
    'Module::Build' => 0,
    'Test::More' => 0,
    'File::Spec::Functions' => 0,
    'IO::File' => 0,
    'IO::Uncompress::Unzip' => 0,
    'File::Path' => 0,
  },
  requires => {
    'File::ShareDir' => 0,
  },
  meta_merge => {
    resources => {
      homepage => 'https://github.com/hoytech/Alien-Electron',
      bugtracker => 'https://github.com/hoytech/Alien-Electron/issues',
      repository => 'git://github.com/hoytech/Alien-Electron.git',
    },
  },
);

$build->create_build_script;
