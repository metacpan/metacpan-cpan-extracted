use strict;
use warnings;
 
use Alien::Base::ModuleBuild;
 
my $builder = Alien::Base::ModuleBuild->new(
  module_name => 'Alien::LuaJIT',
  license => 'perl',
  configure_requires => {
    'Alien::Base' => '0.003',
    'Module::Build' => 0.38,
  },
  requires => {
    'perl' => '5.14.0',
    'parent' => '0',
    'Alien::Base' => 0,
  },
  dist_author => 'Steffen Mueller <smueller@cpan.org>',
  alien_name => 'luajit',
  alien_repository => {
    protocol => 'local',
    location => 'inc',
    pattern  => qr/^LuaJIT-(\d[\d\.]*)\.tar\.gz$/,
  },
  alien_build_commands => [
    q#%x -MExtUtils::Command -e cp ../../inc/Makefile .#,
    q#PREFIX=%s make#
  ],
  alien_install_commands => [
    q#PREFIX=%s make install#
  ],
);

$builder->create_build_script;
