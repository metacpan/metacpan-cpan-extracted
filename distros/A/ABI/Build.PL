#$Id: Build.PL,v 1.1.2.3 2006/11/20 03:23:26 malay Exp $
use strict;
use warnings;
use Module::Build;
use Module::Build::Compat;

my $build = Module::Build->new(
	module_name        => 'ABI',
	license            => 'perl',
	dist_author	=> 'Malay <malay@bioinformatics.org>',
	dist_version_from => 'ABI.pm',
	build_requires =>{
		'Test::More' =>0,
	},
	add_to_cleanup => ['ABI-*'],
	create_makefile_pl => 'traditional',
	
);

$build->create_build_script();

Module::Build::Compat->create_makefile_pl('traditional', $build);
