use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'BIND::SDB::LDAP::Helper',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/BIND/SDB/LDAP/Helper.pm',
			  ABSTRACT_FROM       => 'lib/BIND/SDB/LDAP/Helper.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  INST_SCRIPT => 'bin',
			  PREREQ_PM => {
							'Test::More' => 0,
							'Config::IniHash'=>0,
							'File::BaseDir'=>0,
							'Net::LDAP'=>0,
							'Net::LDAP::Entry'=>0,
							'Net::LDAP::AutoDNs'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'BIND-SDB-LDAP-Helper-*' },
			  );
