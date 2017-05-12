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
    NAME                => 'Asm::Z80::Table',
    AUTHOR              => q{Paulo Custodio <pscust@cpan.org>},
    VERSION_FROM        => 'lib/Asm/Z80/Table.pm',
    ABSTRACT_FROM       => 'lib/Asm/Z80/Table.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Data::Dumper' 				=> 2.128,
        'File::Basename'			=> 0,
        'File::Slurp' 				=> 9999.13,
		'Iterator::Array::Jagged'	=> 0.05,
		'List::MoreUtils'			=> 0.22,
        'Test::More' 				=> 0.96,	# needs done_testing()
		'Text::Template'			=> 1.45,
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
                    url  => 'git://github.com/pauloscustodio/perl-Asm-Z80-Table.git',
                    web  => 'https://github.com/pauloscustodio/perl-Asm-Z80-Table',
                },
            },
          })
    ),

    clean               => { FILES => 'Asm-Z80-Table-*' },
);

sub MY::postamble {
	return q{

# generate the lib/Asm/Z80/Table.pm file
lib/Asm/Z80/Table.pm : tools/build_Table.pl tools/Table_template.pm tools/Z80_instructions.dat
	$(PERLRUN) tools/build_Table.pl Asm::Z80::Table lib/Asm/Z80/Table.pm

};
}
