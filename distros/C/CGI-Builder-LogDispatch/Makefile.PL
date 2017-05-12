use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CGI-Builder-LogDispatch',
    'VERSION_FROM'	=> 'lib/CGI/Builder/LogDispatch.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'Carp'          => 0,
		'CGI::Builder'  => 1.11,
        'Log::Dispatch' => 2.0,
		'Date::Format'  => 0,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/CGI/Builder/LogDispatch.pm', # retrieve abstract from module
       AUTHOR     => 'Vincent Veselosky <http://control-escape.com>') : ()),
);
