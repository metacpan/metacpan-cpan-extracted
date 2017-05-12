use strict;
use warnings;

use Alien::Base::ModuleBuild;

my $builder = Alien::Base::ModuleBuild->new(
  'meta-spec' => {
    version => '2',
    url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
  },
  module_name => 'Alien::GEOS',
  dist_abstract => 'Build and install GEOS',
  license => 'perl',
  configure_requires => {
    'Alien::Base' => 0,
  },
  requires => {
    'perl' => '5.8.1',
    'Alien::Base' => 0,
  },
  dist_author => 'Alessandro Ranellucci <aar@cpan.org>',
  alien_name => 'GEOS',
  alien_repository => {
    protocol => 'http',
    host     => 'download.osgeo.org',
    location => '/geos/',
    pattern  => qr/geos-(\d+\.\d+\.\d+)\.tar\.bz2$/,
  },
  alien_build_commands => [
    '%pconfigure --prefix=%s --enable-shared', 
    'make',
    'make install'
  ],
  alien_provides_libs => '-lgeos',
  resources => {
    bugtracker  => {
      web    => 'http://github.com/alexrj/Alien-GEOS/issues',
      mailto => 'aar@cpan.org',
    },
    repository  => {
      url  => 'git://github.com/alexrj/Alien-GEOS.git',
      web  => 'http://github.com/alexrj/Alien-GEOS',
      type => 'git',
    },
  },
);
$builder->create_build_script;
