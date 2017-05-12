use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'Bundle::Tk_OS2src',
	VERSION_FROM	=> 'Bundle/Tk_OS2src.pm',
	'dist'		=> {
				COMPRESS => 'gzip -9f',
				SUFFIX   => '.gz', 
				DIST_DEFAULT => 'all tardist',
			   },

);
