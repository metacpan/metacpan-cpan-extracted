##-*- Mode: CPerl -*-
use strict;
use warnings;
use Alien::Base::ModuleBuild;

##-- we don't expect moot to build anywhere but linux
die("cowardly refusing to build on non-linux system; edit Build.PL and try again!") if ($^O !~ /linux/i);

my $builder = Alien::Base::ModuleBuild->new
  (
   module_name => 'Alien::Moot',
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
   alien_name => 'moot',
   alien_repository => {
			protocol => 'http',
			host     => 'kaskade.dwds.de',
			location => '~moocow/mirror/projects/moot/',
			pattern  => qr/^moot-([\d\.\-]+)\.tar\.gz$/,
		       },
   alien_build_commands => [
			    '%c --prefix=%s --disable-doc --enable-shared --enable-static',
			    'make',
			   ],
   ##
   alien_isolate_dynamic => 0, ##-- 'share'-mode builds don't work for Moot module with alien_isolate_dynamic=>1
   ##
   #sign => 1,
   #meta_merge => { ... },
   ##
   create_readme => 1,
  );
$builder->create_build_script;

