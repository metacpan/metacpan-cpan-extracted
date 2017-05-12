#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Basename;
use File::Spec;
use lib 't';
use env;

# variables
my $sep = "\t";
my $seqFile = $ENV{'seq_file'};
my $expectedFile = $ENV{'expected_file'};
my $tRNAFile = $ENV{'tRNA_file'};
BAIL_OUT("environment variables NOT found")
unless($expectedFile and $seqFile and $tRNAFile);
my $dir = dirname(__FILE__);
my $caiFile = File::Spec->catfile($dir,"cai.out");
my $taiFile = File::Spec->catfile($dir,"tai.out");

my $module;
BEGIN {
	plan tests => 6;
	$module = 'Bio::CUA::CUB::Builder';
    use_ok( $module ) or 
	BAIL_OUT("Can not load $module");
}

#diag( "Testing Bio::CUA $Bio::CUA::VERSION, Perl $], $^X" );
my $expectedData = _read_data($module);

my $builder = $module->new(-codon_table => 1);

my $rscu = $builder->build_rscu($seqFile,5,0.5);
my $caiMax  = $builder->build_cai($seqFile,5,'max',$caiFile);
my $caiMean = $builder->build_cai($seqFile,5,'mean');
my $caiBack = $builder->build_b_cai($seqFile,$seqFile,5);
my $tai = $builder->build_tai($tRNAFile,$taiFile);

#rscu
ok(_cmp_hash($rscu,    $expectedData->{'rscu'}), "RSCU");
# original CAI
ok(_cmp_hash($caiMax,  $expectedData->{'cai_max'}), "CAI");
# CAI normalized by mean fraction per AA
ok(_cmp_hash($caiMean, $expectedData->{'cai_mean'}), "CAI(mean)");
# CAI normalized by RSCU from background data
ok(_cmp_hash($caiBack, $expectedData->{'cai_back'}), "CAI(back)");
# tAI
ok(_cmp_hash($tai,     $expectedData->{'tai'}), "tAI");

exit 0;

sub _cmp_hash
{
	my ($h1,$h2) = @_;

	return 0 unless(keys(%$h1) == keys(%$h2));

	my $cutoff = 1e-8; 
	while(my ($k1, $v1) = each %$h1)
	{
		return 0 if($v1 - $h2->{$k1} > $cutoff);
	}
	return 1;
}


sub _read_data
{
	my $section = shift;

	open(E,"< $expectedFile") 
		or BAIL_OUT("Can not read expected data from $expectedFile");

	my %hash;
	while(<E>)
	{
		next unless /^>>\Q$section\E$/;# find the starting point
		my $subsect;
		while(<E>)
		{
			last if /^<<\Q$section\E/; # end of the section
			next if /^\s*#/ or /^#/;
			chomp;
			if(/^>/)
			{
				($subsect) = /^>>>(\S+)/ 
					or BAIL_OUT("Match subsection failed");
				next;
			}
			my ($key, $val, $codons) = split $sep;
			if($codons) # there are more values
			{
				$hash{$subsect}{$key}{$val} = [split ',', $codons];
			}else
			{
				$hash{$subsect}{$key} = $val;
			}
		}
		last;
	}
	close E;

	return \%hash;
}

