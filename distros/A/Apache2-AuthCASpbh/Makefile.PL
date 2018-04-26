use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Apache2::AuthCASpbh',
    ABSTRACT         => 'CAS SSO integration for Apache/mod_perl',
    AUTHOR           => q{Paul B. Henson <henson@acm.org>},
    VERSION_FROM     => 'lib/Apache2/AuthCASpbh.pm',
    LICENSE          => 'GPL_3',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'mod_perl2'			=> 0,
        'Apache::Session::Browseable'	=> 0,
        'DBD::SQLite'			=> 0,
	'HTTP::Cookies'			=> 6.40.0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
