use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Business::Shipping::MRW',
    AUTHOR           => q{Harun Delgado <hdp@djmania.es>},
    VERSION_FROM     => 'lib/Business/Shipping/MRW.pm',
    ABSTRACT_FROM    => 'lib/Business/Shipping/MRW.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'JSON::XS'     => 2.34,
        'MIME::Base64' => 3.10,
	'XML::Simple'  => 2.20,
    },
    META_MERGE => {
	'meta-spec' => { version => 2 },
	resources => {
	    repository => {
		type => 'git',
		url  => 'https://github.com/SeHarrys/Perl-MRW-WebServices.git',
		web  => 'https://github.com/SeHarrys/Perl-MRW-WebServices',
	    },
	},
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Business-Shipping-MRW-*' },
);
