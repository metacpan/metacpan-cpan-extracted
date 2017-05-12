use strict;
use warnings;

use Alien::Base::ModuleBuild;
use Config;


my $builder = Alien::Base::ModuleBuild->new(
  module_name => 'Alien::LMDB',
  dist_abstract => 'Build and install the LMDB embedded database',
  license => 'openldap',
  alien_msys => 1,
  alien_bin_requires => {
    'Alien::gmake' => 0,
  },
  configure_requires => {
    'Alien::Base::ModuleBuild' => 0,
    'Module::Build' => '0.38',
  },
  requires => {
    'perl' => '5.8.1',
    'Alien::Base' => 0,
  },
  dist_author => 'Doug Hoyte <doug@hcsw.org>',
  meta_merge => {
      resources => {
          homepage => 'https://github.com/hoytech/Alien-LMDB',
          bugtracker => 'https://github.com/hoytech/Alien-LMDB/issues',
          repository  => 'git://github.com/hoytech/Alien-LMDB.git',
      },
  }, 

  alien_name => 'lmdb',
  ## https://github.com/LMDB/lmdb/releases
  alien_repository => {
    protocol => 'local',
    location => 'inc',
    pattern  => qr/^LMDB_([\d.]+)\.tar\.gz$/,
  },
  alien_build_commands => [
    "%{gmake} -C libraries/liblmdb/ CC=$Config{cc}",
  ],
  alien_test_commands => [
    "%{gmake} -C libraries/liblmdb/ CC=$Config{cc} test > @{[ $^O eq 'MSWin32' ? 'NUL' : '/dev/null' ]}",
  ],
  alien_install_commands => [
    "%{gmake} -C libraries/liblmdb/ CC=$Config{cc} install prefix=%s",
  ],
);

$builder->create_build_script;
