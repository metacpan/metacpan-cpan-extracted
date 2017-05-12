use strict;

use lib q(.);
use ThrustModuleBuild;

my $build = ThrustModuleBuild->new(
  module_name => 'Alien::Thrust',
  dist_abstract => 'Download and install the Thrust cross-platform GUI framework',
  dist_author => 'Doug Hoyte <doug@hcsw.org>',
  license => 'perl',
  configure_requires => {
    'Module::Build' => 0,
  },
  build_requires => {
    'Module::Build' => 0,
    'LWP::UserAgent' => 0,
    'LWP::Protocol::https' => 0,
    'Mozilla::CA' => 0,
    'Test::More' => 0,
    'IPC::Open2' => 0,
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
      homepage => 'https://github.com/hoytech/Alien-Thrust',
      bugtracker => 'https://github.com/hoytech/Alien-Thrust/issues',
      repository => 'git://github.com/hoytech/Alien-Thrust.git',
    },
  },
);

$build->create_build_script;
