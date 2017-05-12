use v5.10;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::DDFlare',
    AUTHOR           => q{Peter Roberts <me+dev@peter-r.co.uk>},
    VERSION_FROM     => 'lib/App/DDFlare.pm',
    ABSTRACT_FROM    => 'lib/App/DDFlare.pm',
    LICENSE          => 'MIT',
    PL_FILES         => {},
    EXE_FILES        => [ 'script/ddflare' ],
    MIN_PERL_VERSION => v5.10,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	'Net::DNS::CloudFlare::DDNS' => 0.03,
	'Readonly' => 1.03,
	'YAML::Any' => 0.77,
	'Getopt::Long' => 2.39,
	'Pod::Usage' => 1.61
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-DDFlare-*' },
);
