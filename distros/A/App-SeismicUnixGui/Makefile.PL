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
        EXE_FILES     => [qw(
		./lib/App/SeismicUnixGui/script/post_install_scripts.sh
		./lib/App/SeismicUnixGui/script/post_install_env.pl
		./lib/App/SeismicUnixGui/script/post_install_c_compile.pl
		./lib/App/SeismicUnixGui/script/post_install_fortran_compile.pl
		)],
	PREREQ_PM     => {
		
		'Moose'           => '2.2015',
		'Shell'           => '0.73.1',
		'aliased'         => '0.34',
		'namespace::autoclean' => '0.29',
		'Module::Refresh' => '0.18',
		'PDL'             => '2.080',
		'Tk'              => '804.036',
		'File::ShareDir'  => '1.118',		
		'Clone'           => '0.45',
		'File::Slurp'     => '9999.32',
		'MIME::Base64'    => '3.16',
		'Time::HiRes'     => '1.9764',

	},

	TEST_REQUIRES => {
		          'Test::Compile::Internal' => '1.3',
	},

	# only needed during build but not later
#	BUILD_REQUIRES => {
#				'File::Tail' => '0'
#	},

	# Documentation accessible within the GUI with Mouse-button-3 click
	# So man files are not used currently
	MAN3PODS => {},

	dist => {
		COMPRESS => 'gzip -9f',
		SUFFIX   => 'gz',

	},

	test => { TESTS => 't/*.t',

	}
	
	);

# post-installation required scripts
	
sub MY::postamble {
	return <<'END';
install ::
	perl ./lib/App/SeismicUnixGui/script/post_install_env.pl
END
}


