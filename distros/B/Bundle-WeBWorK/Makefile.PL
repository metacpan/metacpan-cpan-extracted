use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              	=> 'Bundle::WeBWorK',
    ABSTRACT	      	=> 'Install many prerequisites for WeBWorK',
    LICENSE	      	=> 'perl',
    VERSION_FROM      	=> 'WeBWorK.pm', # finds $VERSION
    PREREQ_PM         	=> {}, # e.g., Module::Name => 1.1
    "dist" 		=> { 	SUFFIX   => ".gz", 
	    			DIST_DEFAULT => 'all tardist', 
				COMPRESS => "gzip -9f", 
				ZIP_FLAGS => '-pr9' } #copied from Bundle::Bugzilla
);
