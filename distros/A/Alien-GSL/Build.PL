use strict;
use warnings;

use Alien::Base::ModuleBuild;

my $builder = Alien::Base::ModuleBuild->new(
  module_name => 'Alien::GSL',
  dist_abstract => 'Easy installation of the GNU Scientific Library',
  license => 'perl',
  configure_requires => {
    'Alien::Base::ModuleBuild' => 0,
    'Module::Build' => '0.38',
  },
  requires => {
    'perl' => '5.8.1',
    'parent' => 0,
    'Alien::Base' => 0,
  },
  dist_author => 'Joel A. Berger <joel.a.berger@gmail.com>',
  alien_name => 'gsl',
  alien_repository => [
    {
      protocol => 'ftp',
      host     => 'ftp.gnu.org',
      location => '/gnu/gsl',
      pattern  => qr/^gsl-([\d\.]+)\.tar\.gz$/,
    },
  ],
  meta_merge => {
    resources => {
      repository => 'https://github.com/Perl5-Alien/Alien-GSL', 
      bugtracker => 'https://github.com/Perl5-Alien/Alien-GSL/issues',
    },
  },
);
$builder->create_build_script;


