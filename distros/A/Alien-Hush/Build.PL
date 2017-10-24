use strict;
use warnings;
use File::Spec::Functions;
use Alien::Base::ModuleBuild;

my $builder          = Alien::Base::ModuleBuild->new(
  module_name        => 'Alien::Hush',
  dist_abstract      => 'Easy installation of the Hush cryptocoin full node daemon',
  license            => 'perl',
  configure_requires => {
    'Alien::Base::ModuleBuild' => 0,
    'Module::Build'            => '0.38',
  },
  requires => {
    'perl'             => '5.8.1',
    'parent'           => 0,
    'Alien::Base'      => '1.25',
    'Alien::Autotools' => 0,
  },
  dist_version     => '0.8889',
  dist_author      => 'Duke Leto <duke@leto.net>',
  alien_name       => 'hush',
  alien_env        => {
      HUSH_PUPPY   => 1,
  },
  alien_repository => [
    {
      # Hardcoded to our latest release
      exact_filename => 'hush-1.0.12.tar.gz',
      location       => 'src',
      protocol       => 'local',
    },
  ],
  alien_build_commands => [
      # TODO: detect number of procs
     catfile('zcutil','build.sh') . " -j2",
  ],

  meta_merge => {
    resources => {
      repository => 'https://github.com/leto/Alien-Hush',
      bugtracker => 'https://github.com/leto/Alien-Hush/issues',
    },
  },
);
$builder->create_build_script;
print "Have a Hush Puppy kind of day!\n";

