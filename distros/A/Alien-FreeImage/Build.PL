use strict;
use warnings;

use lib 'inc';

my $package = $^O eq 'MSWin32' ? 'My::Builder::Windows' :
              $^O eq 'cygwin'  ? 'My::Builder::Cygwin'  :
              'My::Builder::Unix';

eval "require $package" or die "Require '$package' failed: $@\n";
warn "Gonna use '$package' class ...\n";

my $builder = $package->new(
  module_name        => 'Alien::FreeImage',
  dist_version_from  => 'lib/Alien/FreeImage.pm',
  dist_author        => 'KMX <kmx@cpan.org>',
  license            => 'perl',
  requires => {
    'perl'              => '5.008',
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
  },
  configure_requires => {
    'perl'              => '5.008',
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
    'Module::Build'     => 0,
    'File::Path'        => 0,
    'ExtUtils::Command' => 0,
  },
  build_requires => {
    'perl'              => '5.008',
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
    'Module::Build'     => 0,
    'File::Path'        => 0,
    'ExtUtils::Command' => 0,
    'Test::More'        => 0,
  },
  share_dir          => 'sharedir',
  add_to_cleanup     => [ 'build_done' ], # 'Alien-FreeImage-*'
  create_readme      => 1,
  no_index           => { directory => ['src'] },
  meta_merge => {
    resources => {
      repository => 'https://github.com/kmx/alien-freeimage',
      bugtracker => 'https://github.com/kmx/alien-freeimage/issues',
    },
  },
  dist => {
      ($^O eq 'MSWin32' ? (TAR => 'ptar', TARFLAGS => '-c -C -f') : (TARFLAGS => '--owner=0 --group=0 -cvf')),
  },
);

$builder->create_build_script();
# delete build marker (= force rebuild after running Build.PL)
unlink 'build_done';
