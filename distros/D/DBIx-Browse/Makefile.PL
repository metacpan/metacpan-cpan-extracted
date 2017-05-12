use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'      => 'DBIx::Browse',
	      'PREREQ_PM' => {
		  'DBI'		=> '1.00',
                  'Test::More'  => '0.45'
		  },
	      'VERSION_FROM' => 'Browse.pm', # finds $VERSION
);
