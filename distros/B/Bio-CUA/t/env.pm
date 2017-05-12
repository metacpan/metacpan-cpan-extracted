package env;

use File::Spec;

#	my $os = $^O;
#	my $set = $os =~ /MSWin/i? 'set' : 'export';
	my $expFile  = File::Spec->catfile('t', 'expected.tsv');
	my $seqFile  = File::Spec->catfile('t', 'test.fa');
	my $tRNAFile = File::Spec->catfile('t', 'dmel_r5_apr2006.tRNA_copy');

$ENV{'expected_file'} = $expFile;
$ENV{'seq_file'}      = $seqFile;
$ENV{'tRNA_file'}     = $tRNAFile;

1;
