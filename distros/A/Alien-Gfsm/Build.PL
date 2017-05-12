##-*- Mode: CPerl -*-
use strict;
use warnings;

use Alien::Base::ModuleBuild;

my $builder = Alien::Base::ModuleBuild->new
  (
   module_name => 'Alien::Gfsm',
   license => 'perl',
   configure_requires => {
			  'Alien::Base::ModuleBuild'  => '0.027',
			  'Module::Build' => '0.38',
			 },
   test_requires => {
		     #'File::Which'   => 0,
		     'Test::More' => 0, ##-- 1.001002
		     'Text::ParseWords' => 0, ##-- 3.29
		    },
   requires => {
		'perl'        => '5.8.9',
		'Alien::Base' => '0.005',
	       },
   dist_author => 'Bryan Jurish <moocow@cpan.org>',
   alien_name => 'gfsm',
   alien_repository => {
			protocol => 'http',
			host     => 'kaskade.dwds.de',
			location => '~moocow/mirror/projects/gfsm/',
			pattern  => qr/^gfsm-([\d\.\-]+)\.tar\.gz$/,
		       },
   alien_build_commands => [
			    '%c --prefix=%s --disable-programs --disable-doc --enable-shared --enable-static',
			    'make',
			   ],
   alien_isolate_dynamic => 1,
   ##
   #sign => 1,
   #meta_merge => { ... },
   ##
   create_readme => 1,
  );
$builder->create_build_script;

