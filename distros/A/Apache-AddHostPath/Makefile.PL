use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'	=> 'Apache::AddHostPath',
	'VERSION_FROM' => 'AddHostPath.pm', # finds $VERSION
	'dist'	=> {
		PREOP => 'pod2text AddHostPath.pm > README',
		COMPRESS => 'gzip -9f',
		SUFFIX => 'gz',
	},
);
