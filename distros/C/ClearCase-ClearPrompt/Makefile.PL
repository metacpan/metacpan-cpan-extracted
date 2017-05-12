use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'ClearCase::ClearPrompt',
    'VERSION_FROM' => 'ClearPrompt.pm', # finds $VERSION
    'dist' => {
	  DIST_DEFAULT => 'all tardist',
	  SUFFIX => '.gz',
	  COMPRESS => 'gzip -f',
    },
);
