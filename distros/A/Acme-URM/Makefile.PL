use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'			=> 'Acme::URM',
	'VERSION_FROM'	=> 'lib/Acme/URM.pm',		# finds $VERSION
	'PREREQ_PM'		=> {
		'Data::Dumper'	=> 0,
	},
);

