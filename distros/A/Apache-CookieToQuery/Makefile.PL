use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Apache::CookieToQuery',
    VERSION_FROM => 'lib/Apache/CookieToQuery.pm', # finds $VERSION
    AUTHOR       => 'Alex Pavlovic (alex.pavlovic@taskforce-1.com)',
    ABSTRACT     => 'Rewrite requested uri by adding cookie information',
    PREREQ_PM   => {
	'Apache::Cookie'	=> '0', 
    }
);
