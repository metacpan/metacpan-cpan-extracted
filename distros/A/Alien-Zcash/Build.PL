use strict;
use warnings;

use Alien::Base::ModuleBuild;

my $builder          = Alien::Base::ModuleBuild->new(
  module_name        => 'Alien::Zcash',
  dist_abstract      => 'Easy installation of the Zcash cryptocoin full node daemon',
  license            => 'perl',
  configure_requires => {
    'Alien::Base::ModuleBuild' => 0,
    'Module::Build'            => '0.38',
  },
  requires => {
    'perl'        => '5.8.1',
    'parent'      => 0,
    'Alien::Base' => 0,
  },
  dist_version     => '0.01',
  dist_author      => 'Duke Leto <duke@leto.net>',
  alien_name       => 'zcash',
  alien_repository => [
    {
      exact_filename => 'zcash-1.0.12.tar.gz',
      location       => 'src',
      protocol       => 'local',
    },
  ],
  alien_build_commands => [
      # TODO: detect number of procs
    './zcutil/build.sh -j2',
  ],

  meta_merge => {
    resources => {
      repository => 'https://github.com/leto/Alien-Zcash',
      bugtracker => 'https://github.com/leto/Alien-Zcash/issues',
    },
  },
);
$builder->create_build_script;
print "Have an awesome day, full of cryptocoinz!\n";

