use strict;
use lib 'inc';
use Alien::UnRTF::ModuleBuild;
 
my $builder = Alien::UnRTF::ModuleBuild->new(
  module_name => 'Alien::UnRTF',
  dist_abstract => 'Build and make available the unrtf tool',
  configure_requires => {
    'Module::Build' => 0.42,
    'Alien::Base::ModuleBuild' => 0,
  },
  requires => {
    'Alien::Base' => 0,
  },
  dist_author => 'Joenio Costa <joenio@joenio.me>',
  license => 'perl',
  meta_merge => {
    resources => {
      repository => 'http://github.com/joenio/p5-alien-unrtf'
    }
  },
);
 
$builder->create_build_script;
