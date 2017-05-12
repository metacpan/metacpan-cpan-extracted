#!/usr/bin/perl
use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'DJabberd::Authen::Dovecot',
	VERSION_FROM => 'lib/DJabberd/Authen/Dovecot.pm',
	ABSTRACT_FROM => 'lib/DJabberd/Authen/Dovecot.pm',
	PREREQ_PM => {
		'DJabberd' => '0.80',
		'Socket' => '0',
		'MIME::Base64' => '0',
	},
	AUTHOR => 'Ruslan N. Marchenko <me@ruff.mobi>',
);
