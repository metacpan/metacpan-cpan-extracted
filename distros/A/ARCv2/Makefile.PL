use 5.008;
use ExtUtils::MakeMaker;
use strict;
use lib "scripts";

use PBConfig;

@config = (
	[ "ConfigPath" , "s", "/etc/arcx", "Configuration path, where ARCv2 shall find its files." ],
	[ "DefaultPort", "i", "4242", "Default port, client and server use this as default." ],
	[ "DefaultHost", "s", "arcdsrv", "Default host, client uses this as default." ],
	[ "DefaultPIDFile", "s", "/var/run/arcxd.pid", "Default PID file, server uses this as default" ],
);

$fn = "lib/Arc.pm";

$usage = \&Usage;

opt_parse;

# Checking values

file_parse;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'		=> 'Patrick Boettcher <patrick.boettcher@desy.de>',
    'ABSTRACT'		=> 'Authenticated Remote Command v2',
    'DISTNAME'		=> 'ARCv2',
    'NAME'		=> 'Arc',
    'VERSION_FROM'	=> 'lib/Arc.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
		'Authen::SASL' => '2.06',
		'Authen::SASL::Cyrus' => '0.10',
		'IO::Pipe' => '0.0',
		'MIME::Base64' => '0.0',
		'IO::Socket::INET' => '0.0',
		'IO::Select' => '0.0',
		'Test::More' => '0.0',
		'Config::IniFiles' => '0.0',
		'Term::ReadKey' => '0.0',
		'Net::Server::PreFork' => '0.85',
		'Term::ReadLine' => '0.0',
    },
    dist		=> {
		COMPRESS => 'gzip --best',
		SUFFIX   => 'gz',
		PREOP => 'make -C doc'
    }, 
    'EXE_FILES'		=> [ 'scripts/arcx', 'scripts/arcxd' ],
);

sub Usage {
	print STDERR <<EOH;
ARCv2 Makefile.PL 

Usage: perl $0 [options]

Possible options are:
     --help          See this help
EOH
	opt_help();

	print @_,"\n";
	exit 1;
}
