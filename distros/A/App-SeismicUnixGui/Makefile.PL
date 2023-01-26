use strict;
use warnings;

use 5.26.1;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'App::SeismicUnixGui',
	AUTHOR        => 'Juan Lorenzo <gllore@lsu.edu>',
	VERSION_FROM  => 'lib/App/SeismicUnixGui.pm',
	ABSTRACT_FROM => 'lib/App/SeismicUnixGui.pm',
	LICENSE       => 'perl',
	PREREQ_PM     => {
		
		'Moose'           => '2.2015',
		'Shell'           => '0.73.1',
		'aliased'         => '0.34',
		'namespace::autoclean' => '0.29',
		'Module::Refresh' => '0.18',
		'PDL'             => '2.080',
		'Tk'              => '804.036',
		'Tk::JFileDialog' => '2.20',
		'Tk::JBrowseEntry'=> '5.25',
		'File::ShareDir'  => '1.118',		
		'Clone'           => '0.45',
		'File::Slurp'     => '9999.32',
		'MIME::Base64'    => '3.16',
		'Time::HiRes'     => '1.9764',

	},

	TEST_REQUIRES => {
		          'Test::Compile::Internal' => '3.1.0',
	},

	# only needed during build but not later
	BUILD_REQUIRES => {
		#		'Other::Module' => '0'
	},

	# required scripts
	PL_FILES => {
		'./lib/App/SeismicUnixGui/script/post_install_c_compile.pl' => 'SeismicUnixGui',
		'./lib/App/SeismicUnixGui/script/post_install_fortran_compile.pl' => 'SeismicUnixGui',
		'./lib/App/SeismicUnixGui/script/post_install_env.pl' => 'SeismicUnixGui',
	},

	# Documentation accessible within the GUI with Mouse-button-3 click
	# So man files are not used currently
	MAN3PODS => {},

	dist => {
		COMPRESS => 'gzip -9f',
		SUFFIX   => 'gz',

	},

	test => { TESTS => 't/*.t',

	},

);
