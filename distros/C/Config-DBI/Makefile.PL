use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Config::DBI',
    'VERSION_FROM'	=> 'lib/Config/DBI.pm', # finds $VERSION
    'PREREQ_PM'		=> {

			    Config::ApacheFormat => 1.2,
			    Term::ReadKey        => 2.21,
			    DBI                  => 1.38

			   }, # e.g., Module::Name => 1.1
);
