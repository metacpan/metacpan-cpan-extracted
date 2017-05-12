use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile (

	'ABSTRACT_FROM'			=> 'lib/Data/SimplePath.pm',
	'AUTHOR'			=> 'Stefan Goebel',
	'LICENSE'			=> 'perl',
	'NAME'				=> 'Data::SimplePath',
	'PL_FILES'			=> {},
	'VERSION_FROM'			=> 'lib/Data/SimplePath.pm',
	'BUILD_REQUIRES'		=> {
		'Test::More'		=> '0',
		'Test::NoWarnings'	=> '0',
		'Test::Warn'		=> '0',
	},
	'PREREQ_PM'			=> {
		'Storable'		=> '0',
	},
	'clean'				=> {
		'FILES'			=> 'Data-SimplePath-*'
	},
	'dist'				=> {
		'COMPRESS'		=> 'gzip -9f',
		'SUFFIX'		=> 'gz',
	},

);
