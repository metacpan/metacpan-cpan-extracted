#!/usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.010;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'Asm::Preproc',
    AUTHOR              => 'Paulo Custodio <pscust@cpan.org>',
    VERSION_FROM        => 'lib/Asm/Preproc.pm',
    ABSTRACT_FROM       => 'lib/Asm/Preproc.pm',
    DISTNAME          	=> 'Asm-Preproc',
    PL_FILES            => {},
    PREREQ_PM => {
		'Class::Accessor'				=> 0.51,
		'Data::Dump'					=> 1.23,
		'File::Slurp'					=> 9999.26,
        'Test::More' 					=> 1.302162,
		'Text::Template'				=> 1.55,
 		'Iterator::Simple::Lookahead'	=> 0.09,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	MIN_PERL_VERSION => 5.010,
	LICENSE => 'perl_5',
	META_MERGE => {
            resources => {
                repository  => {
                    type => 'git',
                    url  => 'git://github.com/pauloscustodio/perl-Asm-Preproc.git',
                    web  => 'https://github.com/pauloscustodio/perl-Asm-Preproc',
                },
            },
          },
    clean               => { FILES => [ 'Asm-Preproc-*',
										'*.tmp',
										'*.bak',
									  ]
						   },
);
