##-*- Mode: CPerl -*-
use strict;
use warnings;

use Alien::Base::ModuleBuild;

my $builder = Alien::Base::ModuleBuild->new
  (
   module_name => 'Alien::Unicruft',
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
   alien_name => 'unicruft',
   alien_repository => {
			protocol => 'http',
			host     => 'odo.dwds.de',
			location => '~moocow/software/unicruft/',
			pattern  => qr/^unicruft-([\d\.\-]+)\.tar\.gz$/,
		       },
   alien_build_commands => [
			    '%c --prefix=%s --enable-shared --enable-static FLEX=no BISON=no FLEX=no BISON=no DOXYGEN=no OPTGEN_PERL=no POD2TEXT=no POD2MAN=no POD2HTML=no POD2LATEX=no',
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

