#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.010;
my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    # developer release
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'Asm::Preproc',
    AUTHOR              => q{Paulo Custodio <pscust@cpan.org>},
    VERSION_FROM        => 'lib/Asm/Preproc.pm',
    ABSTRACT_FROM       => 'lib/Asm/Preproc.pm',
    PL_FILES            => {},
    PREREQ_PM => {
		'Carp'							=> 0,
		'Class::XSAccessor'				=> 1.18,
		'Class::XSAccessor::Array'		=> 1.18,
		'Data::Dump'					=> 1.17,
		'File::Find'					=> 0,
		'File::Slurp'					=> 9999.13,
		'File::Spec'					=> 0,
        'Test::More' 					=> 0.96,	# needs done_testing()
		'Text::Template'				=> 1.45,
 		'Iterator::Simple::Lookahead'	=> 0.06,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.010)
        : ()
    ),

    ($mm_ver >= 6.31 ? (LICENSE => 'perl_5_16') : ()),

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository  => {
                    type => 'git',
                    url  => 'git://github.com/pauloscustodio/perl-Asm-Preproc.git',
                    web  => 'https://github.com/pauloscustodio/perl-Asm-Preproc',
                },
            },
          })
    ),

    clean               => { FILES => [ 'Asm-Preproc-*',
										'*.tmp',
										'*.bak',
									  ]
						   },
);
