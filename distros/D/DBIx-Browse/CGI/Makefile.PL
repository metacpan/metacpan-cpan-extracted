use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'      => 'DBIx::Browse::CGI',
	      'PREREQ_PM' => {
		  'CGI'	=> '2.00'
		  },
	      'VERSION_FROM' => 'CGI.pm' # finds $VERSION
);
