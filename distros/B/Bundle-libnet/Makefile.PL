use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'Bundle::libnet',
	VERSION_FROM	=> 'libnet.pm',
	'dist'		=> {
				COMPRESS => 'gzip -9f',
				SUFFIX   => '.gz', 
				DIST_DEFAULT => 'all tardist',
			   },

);
