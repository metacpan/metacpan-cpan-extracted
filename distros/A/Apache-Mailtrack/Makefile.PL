# $Id: Makefile.PL,v 1.1.1.1 2002/07/31 13:10:44 fhe Exp $
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::Mailtrack',
    'VERSION_FROM'	=> 'lib/Apache/Mailtrack.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Data::Serializer'	=> 0.17,
	'DBI'			=> 1.21,
	'Apache::Request'	=> 1.0,
	'mod_perl'		=> 1.26
    	}, # e.g., Module::Name => 1.1
     dist		=> {
     	COMPRESS => 'gzip --force --best'
     	},
);
