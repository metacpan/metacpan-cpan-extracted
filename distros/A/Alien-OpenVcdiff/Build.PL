use strict;
use warnings;

use Alien::Base::ModuleBuild;


## Run this when you change docs so the github README.pod is updated. I'm sure there is a better way with Module::Build ...
## perldoc -uT lib/Alien/OpenVcdiff.pm > README.pod


my $builder = Alien::Base::ModuleBuild->new(
  module_name => 'Alien::OpenVcdiff',
  dist_abstract => 'Build and install open-vcdiff, a binary diff/patch library',
  license => 'apache',
  configure_requires => {
    'Alien::Base::ModuleBuild' => '0.003',
    'Module::Build' => '0.38',
  },
  requires => {
    'perl' => '5.8.1',
    'Alien::Base' => 0,
  },
  dist_author => 'Doug Hoyte <doug@hcsw.org>',
  alien_name => 'OpenVcdiff',
  alien_repository => {
    protocol => 'local',
    location => 'inc',
    pattern  => qr/^open-vcdiff-([\d.]+)\.tar\.gz$/,
  },
  alien_test_commands => [
    'make check',
  ],
  meta_merge => {
      resources => {
          homepage => 'https://github.com/hoytech/Alien-OpenVcdiff',
          bugtracker => 'https://github.com/hoytech/Alien-OpenVcdiff/issues',
          repository  => 'git://github.com/hoytech/Alien-OpenVcdiff.git',
      },
  }, 
);

$builder->create_build_script;
