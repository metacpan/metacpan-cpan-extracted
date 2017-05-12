use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'Bundle::MP3',
	VERSION_FROM	=> 'MP3.pm',
	'dist'		=> {
				COMPRESS => 'gzip -9f',
				SUFFIX   => '.gz', 
				DIST_DEFAULT => 'all tardist',
			   },

);
