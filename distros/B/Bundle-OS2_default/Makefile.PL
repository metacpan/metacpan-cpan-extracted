use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'Bundle::OS2_default',
	VERSION_FROM	=> 'Bundle/OS2_default.pm',
	'dist'		=> {
				COMPRESS => 'gzip -9f',
				SUFFIX   => '.gz', 
				DIST_DEFAULT => 'all tardist',
			   },

);
