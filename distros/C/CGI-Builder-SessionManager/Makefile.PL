use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'CGI::Builder::SessionManager',
	VERSION_FROM      => 'lib/CGI/Builder/SessionManager.pm', # finds $VERSION
	PREREQ_PM         => {
		'CGI::Builder' => 1.2,
		'Apache::SessionManager' => 1.01
	}, # e.g., Module::Name => 1.1
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM => 'lib/CGI/Builder/SessionManager.pm', # retrieve abstract from module
		AUTHOR         => 'Enrico Sorcinelli <enrico@sorcinelli.it>') : ()),
);
