use strict;
use warnings;

use lib 'inc';
use My::ModuleBuild;

my $builder = My::ModuleBuild->new(
  module_name => 'Alien::FFCall',
  dist_abstract => 'Build and install libffcall',
  license => 'perl',
  configure_requires => {
    'Alien::Base::ModuleBuild' => 0.021,
    'parent'      => 0,
  },
  requires => {
    'perl' => '5.8.1',
    'Alien::Base' => 0.021,
  },
  dist_author => 'David Mertens <dcmertens.perl@gmail.com>',
  alien_name => 'ffcall',
  alien_repository => {
    protocol => 'local',
    pattern  => qr/ffcall-([\d.]+)\.tar\.gz$/,
  },
  alien_build_commands => [
    '%c --prefix=%s --enable-shared', 
    'make',
  ],
  alien_install_commands => [
    'make install',
  ],
  alien_isolate_dynamic => 1,
  alien_provides_libs => '-lavcall -lcallback',
  meta_merge => {
    'meta-spec' => {
      version => '2',
      url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    resources => {
      bugtracker  => {
        web    => 'http://github.com/run4flat/Alien-FFCall/issues',
        mailto => 'dcmertens.perl@gmail.com',
      },
      repository  => {
        url  => 'git://github.com/run4flat/Alien-FFCall.git',
        web  => 'http://github.com/run4flat/Alien-FFCall',
        type => 'git',
      },
    },
  },
);
$builder->create_build_script;
