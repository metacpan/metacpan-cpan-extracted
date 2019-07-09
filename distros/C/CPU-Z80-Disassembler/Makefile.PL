#!/usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.010;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'CPU::Z80::Disassembler',
    AUTHOR              => 'Paulo Custodio <pscust@cpan.org',
    VERSION_FROM        => 'lib/CPU/Z80/Disassembler.pm',
    ABSTRACT_FROM       => 'lib/CPU/Z80/Disassembler.pm',
    DISTNAME          	=> 'CPU-Z80-Disassembler',
    PL_FILES            => {},
    PREREQ_PM => {
		'Asm::Z80::Table'		=> 0.03,
		'Bit::Vector'			=> 7.4,
		'Class::Accessor'		=> 0.51,
		'CPU::Z80::Assembler'	=> 2.18,	# test fails if z80masm is not up-to-date
		'File::Slurp'			=> 9999.26,
		'Test::Output'			=> 1.031,
		'Tie::File'				=> 1.00,
        'Test::More'			=> 1.302162,
		'Path::Tiny'			=> 0.108,
    },
	EXE_FILES => [
		'bin/z80dis',
	],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	MIN_PERL_VERSION 	=> 5.010,
	LICENSE 			=> 'perl_5',
	META_MERGE => {
            resources => {
                repository  => {
                    type => 'git',
                    url  => 'git://github.com/pauloscustodio/perl-CPU-Z80-Disassembler.git',
                    web  => 'https://github.com/pauloscustodio/perl-CPU-Z80-Disassembler',
                },
            },
          },
    clean               => { FILES => 'CPU-Z80-Disassembler-*' },

);

sub MY::postamble {
	return q{

# generate test data files
gen : t/data/zx48_benchmark.dump t/data/zx48_base.asm

t/data/zx48_benchmark.dump : t/tools/build_zx48_dz80.pl t/data/zx48.rom Makefile.PL
	$(PERLRUN) -Ilib t/tools/build_zx48_dz80.pl t/data/zx48.rom t/data/zx48_benchmark.dump

t/data/zx48_base.asm : t/tools/build_zx48_asm.pl t/data/zx48.asm t/tools/Parsezx48.pm Makefile.PL
	$(PERLRUN) -Ilib t/tools/build_zx48_asm.pl t/data/zx48.asm t/data/zx48_base.asm

};
}
