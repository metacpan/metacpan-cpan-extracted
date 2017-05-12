use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::DEC',
    VERSION_FROM      => 'lib/Data/DEC.pm', # finds $VERSION
    PREREQ_PM         => {  # e.g., Module::Name => 1.1
    	'Parse::Highlife' => 0,
    	'Data::Dumper' => 0,
    },
    PMLIBDIRS 		  => [ 'lib', 'lib/Data/DEC' ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/DEC.pm', # retrieve abstract from module
       AUTHOR         => 'Tom Kirchner <tk@activestate.com>') : ()),
);
