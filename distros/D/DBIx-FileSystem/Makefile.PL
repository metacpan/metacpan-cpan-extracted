use ExtUtils::MakeMaker;
#
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'DBIx::FileSystem',
    'VERSION_FROM' => 'FileSystem.pm', # finds $VERSION
    'PREREQ_PM'    => { 
			 'DBI' => 1,
			 'Test::Simple' => 0.47,
		      },

);
