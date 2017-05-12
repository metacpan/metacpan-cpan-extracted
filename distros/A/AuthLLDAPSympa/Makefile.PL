use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Apache2::AuthLLDAPSympa',
    AUTHOR              => 'Sebastien DIAZ <sebastien.diaz AT gmail.com>',
    VERSION_FROM        => 'lib/Apache2/AuthLLDAPSympa.pm',
    ABSTRACT_FROM       => 'lib/Apache2/AuthLLDAPSympa.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'CGI::More' => 0,
	'CGI::Cookie' => 0;	
	'Apache2::Access' => 0,
	'Apache2::SubRequest' => 0,
	'Apache2::RequestRec' => 0,
	'Apache2::RequestUtil' => 0,
	'Apache2::Response' => 0,
	'mod_perl2' => 0,
	'Apache2::Log' => 0,
	'Net::LDAP' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Apache2-AuthSympa-*' },
);
