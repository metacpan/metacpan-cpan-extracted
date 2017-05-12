use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Bio::Tools::ProteinogenicAA',
    AUTHOR           => q{Felipe da Veiga Leprevost <leprevost@cpan.org>},
    VERSION_FROM     => 'lib/Bio/Tools/ProteinogenicAA.pm',
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
	'Moose'			=>	0,
	'namespace::autoclean'	=>	0,
    },
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
    	    resources => {
                homepage   => 'https://github.com/Leprevost/Bio-Tools-ProteinogenicAA',
                repository => 'https://github.com/Leprevost/Bio-Tools-ProteinogenicAA',
                bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-Tools-ProteinogenicAA',
            },
        })
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bio-Tools-ProteinogenicAA-*' },
);
