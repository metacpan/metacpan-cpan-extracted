use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME	=> 'CGI::MultiValuedHash',
	VERSION_FROM => 'lib/CGI/MultiValuedHash.pm', # finds $VERSION
	PREREQ_PM => {
		'Data::MultiValuedHash' => 1.081,
	},
);
