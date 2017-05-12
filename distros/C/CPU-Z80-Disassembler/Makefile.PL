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
    NAME                => 'CPU::Z80::Disassembler',
    AUTHOR              => q{Paulo Custodio <pscust@cpan.org>},
    VERSION_FROM        => 'lib/CPU/Z80/Disassembler.pm',
    ABSTRACT_FROM       => 'lib/CPU/Z80/Disassembler.pm',
    PL_FILES            => {},
    PREREQ_PM => {
		'Asm::Z80::Table'		=> 0.02,
		'Bit::Vector'			=> 7.1,
		'Carp'					=> 0,
		'Class::XSAccessor'		=> 1.08,
		'CPU::Z80::Assembler'	=> 2.13,	# test fails if z80masm is not up-to-date
		'File::Basename'		=> 0,
		'File::Slurp'			=> 9999.12,
		'Getopt::Std'			=> 0,
		'Test::Output'			=> 0.16,
		'Tie::File'				=> 0.96,
        'Test::More'			=> 0.96,	# needs done_testing()
    },
	EXE_FILES => [
		'bin/z80dis',
	],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CPU-Z80-Disassembler-*' },

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
                    url  => 'git://github.com/pauloscustodio/perl-CPU-Z80-Disassembler.git',
                    web  => 'https://github.com/pauloscustodio/perl-CPU-Z80-Disassembler',
                },
            },
          })
    ),
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
