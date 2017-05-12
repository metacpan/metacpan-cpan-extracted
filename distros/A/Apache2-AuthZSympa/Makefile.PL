use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Apache2::AuthZSympa',
    AUTHOR              => 'Dominique Launay <dominique.launay AT renater.fr>',
    VERSION_FROM        => 'lib/Apache2/AuthZSympa.pm',
    ABSTRACT_FROM       => 'lib/Apache2/AuthZSympa.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Apache2::Access' => 0,
	'Apache2::SubRequest' => 0,
	'Apache2::RequestRec' => 0,
	'Apache2::RequestUtil' => 0,
	'Apache2::Response' => 0,
	'Cache::Memcached' => 0,
	'mod_perl2' => 0,
	'Apache2::Log' => 0,
	'SOAP::Lite' => 0,
	'Net::LDAP' => 0,
	'Digest::MD5' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Apache2-AuthSympa-*' },
);
