use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'BaseLib',
    'VERSION_FROM' => 'BaseLib.pm', # finds $VERSION
	dist => {
		COMPRESS => 'gzip -9',
		SUFFIX   => 'gz',
		POSTOP   => 'mv $(DISTVNAME).tar.gz ../',
	},
);
