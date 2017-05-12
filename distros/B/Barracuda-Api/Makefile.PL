use 5.020002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Barracuda::Api',
    VERSION_FROM      => 'lib/Barracuda/Api.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Barracuda/Api.pm', # retrieve abstract from module
    AUTHOR            => 'Mael Regnery <mql@cpan.org>',
    LICENSE           => 'perl',
    PREREQ_PM	      => {
		# Require XML::RPC at least 0.8 (xml_in function)
		"XML::RPC"	=> "0.8",

		# Require Carp at least 1.25
		"Carp"		=> "1.25"
    }
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
