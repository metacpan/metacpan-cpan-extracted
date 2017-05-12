use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'DBIx::Recordset::Playground',
    'VERSION_FROM'	=> 'Playground.tt', # finds $VERSION
    'PREREQ_PM'		=> {
			    DBIx::Recordset => 0.24,
			    DBI => 1.0,
			    DBSchema::Sample => 0.04,
			    Text::Template => 1.44,
        		    Whitespace => 1.02

			   }, # e.g., Module::Name => 1.1
	     );
