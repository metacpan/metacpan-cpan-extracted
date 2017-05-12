use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME			=> 'CGI::Thin',
    VERSION_FROM	=> 'lib/CGI/Thin.pm', # finds $VERSION
	AUTHOR			=> 'R. Geoffrey Avery (modules@PlatypiVentures.com)',
	ABSTRACT		=> 'Module to parse CGI forms',
);
