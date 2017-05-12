use ExtUtils::MakeMaker;
WriteMakefile(
	      'NAME'	     => 'Bundle::Expect',
	      'VERSION_FROM' => 'Bundle-Expect.pm',
	      'dist'         => { COMPRESS => 'gzip -9f',
				  SUFFIX => 'gz',
				  DIST_DEFAULT => 'all tardist',
				},
	      );
