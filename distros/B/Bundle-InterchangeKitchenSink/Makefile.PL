use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Bundle::InterchangeKitchenSink',
    'VERSION_FROM' => 'InterchangeKitchenSink.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
	"dist"     => { SUFFIX   => ".gz", DIST_DEFAULT => 'all tardist',
			    	COMPRESS => "gzip -9f", ZIP_FLAGS => '-pr9' },
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
);
