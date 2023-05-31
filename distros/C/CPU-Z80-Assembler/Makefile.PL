#!/usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.012;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    # developer release
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         	=> 'CPU::Z80::Assembler',
    AUTHOR          => 'Paulo Custodio <pscust@cpan.org>',
    VERSION_FROM 	=> 'lib/CPU/Z80/Assembler.pm',
    ABSTRACT_FROM   => 'lib/CPU/Z80/Assembler.pm',
    DISTNAME        => 'CPU-Z80-Assembler',
    PL_FILES            => {},
    PREREQ_PM 		=> {
		'Asm::Preproc'					=> 1.00,	# no Asm::Preproc::Stream
		'Asm::Z80::Table'				=> 0.02,
		'Capture::Tiny'					=> 0.48,
		'Iterator::Array::Jagged'		=> 0.05,
		'Iterator::Simple::Lookahead'	=> 0.04,
        'Class::Struct'					=> 0,
        'Data::Dump' 					=> 1.08,
        'File::Slurp' 					=> 9999.13,
        'File::Spec' 					=> 0,
		'Path::Tiny'					=> 0.122,
        'Regexp::Trie' 					=> 0.02,
        'Test::More' 					=> 0.96,	# needs done_testing()
        'Text::Tabs' 					=> 2006.1117,
    },
    EXE_FILES    	=> [qw(
        bin/z80masm
    )],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.012)
        : ()
    ),
    ($mm_ver >= 6.31 ? (LICENSE => 'perl_5') : ()),
    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository  => {
                    type => 'git',
                    url  => 'https://github.com/pauloscustodio/perl-CPU-Z80-Assembler.git',
                    web  => 'https://github.com/pauloscustodio/perl-CPU-Z80-Assembler',
                },
				bugtracker => {
					web => 'https://github.com/pauloscustodio/perl-CPU-Z80-Assembler/issues',
				},
			},
          })
    ),
    clean               => { FILES => 'CPU-Z80-Assembler-*' },
);


sub MY::postamble {
	return q{

# generate the parser - developper only, specific Win32
gentools : 
	cd tools 
	$(MAKE)
	cd ..
	$(MAKE)

};
}
