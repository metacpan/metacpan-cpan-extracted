use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'DBIx::OracleSequence',
	'AUTHOR' => 'Doug Bloebaum',
    'VERSION_FROM' => 'OracleSequence.pm', # finds $VERSION
	'PREREQ_PM' => {
	  'DBD::Oracle' => '1',
	  'DBI' => '1',
    }
);
