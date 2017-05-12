use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;

WriteMakefile(
    NAME             => 'Bio::CUA',
    AUTHOR           => q{Zhenguo Zhang <zhangz.sci@gmail.com>},
    VERSION_FROM     => 'lib/Bio/CUA.pm',
    ABSTRACT_FROM    => 'lib/Bio/CUA.pm',
    LICENSE          => 'gpl_3',
	#PL_FILES         => {'other.PL' => ''}, # files run during compilation 
	EXE_FILES        => ["bin/cai_codon.pl",
	                     "bin/tai_codon.pl",
						 "bin/cub_seq.pl",
						 "bin/tabulate_codons.pl"
	                    ], # files in bin directory
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
		'File::Sort'        => 1.01,
		'File::Temp'        => 0,
		'Fcntl'             => 0,
		'parent'            => 0,
		'Getopt::Long'      => 0,
		'Carp'              => 0
    },

	# add more information
	META_MERGE  => {
		resources => {
			homepage => 'http://molevol.altervista.org/'
		}
	},

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bio-CUA-*' },
	test  => { RECURSIVE_TEST_FILES => 1, # test directories in t recursively
		# TESTS => 't/01-seqio.t'
	},
	# environment variables
	macro => {
#		'expected_file' => 't/expected.tsv' # expected results to compare
	}
);

package MY; # other content MakeMaker can't produce

sub postamble
{
	# The return will be directly write to makefile

	# get the command to set environment variables
#	my $os = $^O;
#	my $set = $os =~ /MSWin/i? 'set' : 'export';
#	my $expFile  = File::Spec->catfile('t', 'expected.tsv');
#	my $seqFile  = File::Spec->catfile('t', 'test.fa');
#	my $tRNAFile = File::Spec->catfile('t', 'dmel_r5_apr2006.tRNA_copy');
#
#	my $postamble = <<POST;
#export expected_file = $expFile
#export seq_file = $seqFile
#export tRNA_file = $tRNAFile
#POST

#	return $postamble;
}

# put subroutines here
