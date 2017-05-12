use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Bio::DB::NextProt',
    AUTHOR           => q{Felipe da Veiga Leprevost <leprevost@cpan.org>},
    VERSION_FROM     => 'lib/Bio/DB/NextProt.pm',
    ABSTRACT_FROM    => 'README.pod',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.012000,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
	'Net::FTP::Tiny' => 0,
    },
    PREREQ_PM => {
	'REST::Client'		=> 0,
    },
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
    	    resources => {
                homepage   => 'https://github.com/Leprevost/Bio-DB-NextProt',
                repository => 'https://github.com/Leprevost/Bio-DB-NextProt.git',
                bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-DB-NextProt',
            },
        })
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bio-DB-NextProt-*' },
);
