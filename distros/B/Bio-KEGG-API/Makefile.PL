use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Bio::KEGG::API',
    AUTHOR           => q{Felipe da Veiga Leprevost <leprevost@cpan.org>},
    VERSION_FROM     => 'lib/Bio/KEGG/API.pm',
    ABSTRACT_FROM    => 'README.pod',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moose'					=> 0,
		'namespace::autoclean'	=> 0,
		'REST::Client'			=> 0,
		'Net::FTP::Tiny'		=> 0,
    },
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
    	    resources => {
                homepage   => 'https://github.com/Leprevost/Bio-KEGG-API',
                repository => 'https://github.com/Leprevost/Bio-KEGG-API',
                bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-KEGG-API',
            },
        })
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bio-KEGG-API-*' },
);
