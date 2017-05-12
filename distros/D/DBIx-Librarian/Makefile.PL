use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'DBIx::Librarian',
    'VERSION_FROM'	=> 'Librarian.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    DBI => 1.13,
			    Data::Library => 0.2,
			   },
);
