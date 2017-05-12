use strict;
use warnings;

use Alien::Base::ModuleBuild;

my $builder = Alien::Base::ModuleBuild->new(
  'meta-spec' => {
    version => '2',
    url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
  },
  module_name => 'Alien::qd',
  dist_abstract => 'Build and install libqd',
  license => 'perl',
  configure_requires => {
    'Alien::Base' => 0,
  },
  requires => {
    'perl' => '5.8.1',
    'Alien::Base' => 0,
  },
  dist_author => 'Alessandro Ranellucci <aar@cpan.org>',
  alien_name => 'qd',
  alien_repository => {
    protocol => 'local',
    pattern  => qr/qd-([\d.]+)\.tar\.gz$/,
  },
  alien_build_commands => [
  	'pwd',
    '%pconfigure --prefix=%s --enable-shared', 
    'make',
    'make install'
  ],
  alien_provides_libs => '-lqd',
  resources => {
    bugtracker  => {
      web    => 'http://github.com/alexrj/Alien-qd/issues',
      mailto => 'aar@cpan.org',
    },
    repository  => {
      url  => 'git://github.com/alexrj/Alien-qd.git',
      web  => 'http://github.com/alexrj/Alien-qd',
      type => 'git',
    },
  },
);
$builder->create_build_script;