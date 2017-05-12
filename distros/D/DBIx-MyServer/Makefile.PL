use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'DBIx::MyServer',
	VERSION_FROM      => 'lib/DBIx/MyServer.pm',
	PREREQ_PM         => {
			'Digest::SHA1' => '0.00',
			'DBI' => '0.00',
			'DBD::mysql' => '0.00'
	},
	EXE_FILES	=> [ 'examples/myserver.pl' ],
	($] >= 5.005 ? (
		ABSTRACT_FROM  => 'lib/DBIx/MyServer.pm',
		AUTHOR         => 'Philip Stoev <philip@stoev.org>'
	) : ())
);
