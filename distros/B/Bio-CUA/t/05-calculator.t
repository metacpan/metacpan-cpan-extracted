#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Basename;
use Bio::CUA::SeqIO;
use File::Spec;
use lib 't';
use env;

my $sep = "\t";
my $seqFile = $ENV{'seq_file'};
my $expectedFile = $ENV{'expected_file'};
BAIL_OUT("environment variables NOT found")
unless($expectedFile and $seqFile);
my $dir = dirname(__FILE__);
my $caiFile = File::Spec->catfile($dir, "cai.out");
my $taiFile = File::Spec->catfile($dir, "tai.out");

my $module;
BEGIN {
	plan tests => 7;
	$module = 'Bio::CUA::CUB::Calculator';
    use_ok( $module ) or 
	BAIL_OUT("Can not load $module");
}

ok($caiFile,"CAI file");
ok($taiFile,"tAI file");

#diag( "Testing Bio::CUA $Bio::CUA::VERSION, Perl $], $^X" );
my $expectedData = _read_data($module);

my $calc = $module->new(
			-codon_table => 1,
			-CAI_values  => $caiFile,
			-tAI_values  => $taiFile
		);

my $io = Bio::CUA::SeqIO->new(-file => $seqFile);
my %seqCAIs;
my %seqtAIs;
my %seqENCs;
my %seqENC_rs;

while(my $seq = $io->next_seq)
{
	$seqCAIs{$seq->id} = $calc->cai($seq);
	$seqtAIs{$seq->id} = $calc->tai($seq);
	$seqENCs{$seq->id} = $calc->enc($seq,5);
	$seqENC_rs{$seq->id} = $calc->enc_r($seq,5);
}

# is_deeply can not solve the issue:
# two numbers may differ at a very late position after the decimal
# point, which is just a format difference
ok(_cmp_hash(\%seqCAIs,$expectedData->{'seq_cai'}),"seqs' CAI");
ok(_cmp_hash(\%seqtAIs,$expectedData->{'seq_tai'}),"seqs' tAI");
ok(_cmp_hash(\%seqENCs,$expectedData->{'seq_enc'}),"seqs' ENC");
ok(_cmp_hash(\%seqENC_rs,$expectedData->{'seq_enc_r'}),"seqs' ENC_r");

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

