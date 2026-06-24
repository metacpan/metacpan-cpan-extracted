use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = (
    NAME                => 'Business::BR::NFSe',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/Business/BR/NFSe.pm',
    ABSTRACT_FROM       => 'lib/Business/BR/NFSe.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'         => 0,
        'Carp'               => 0,
	'Encode'             => 0,
	'MIME::Base64'       => 0,
	'Digest::SHA'        => 0,
	'IO::Compress::Gzip' => 0,
	'HTTP::Tiny'         => 0,
	'Crypt::PK::RSA'     => 0,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/garu/Business-BR-NFSe/issues/',
            repository  => 'https://github.com/garu/Business-BR-NFSe',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Business-BR-NFSe-*' },
);

WriteMakefile( %options );
