use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME		=> "Date::Spoken::German",
	VERSION_FROM	=> "German.pm",
	AUTHOR		=> 'Chr. Winter <chrwin@cpan.org>',
	PREREQ_PM	=> {
		"Exporter"	=>	0,
		"POSIX"		=>	0,
	},
	PREREQ_FATAL	=>	1,
);
