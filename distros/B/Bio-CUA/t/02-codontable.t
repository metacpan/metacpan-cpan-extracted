#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use lib 't';
use env;

# variables
my $sep = "\t";
my $seqFile = $ENV{'seq_file'};
my $expectedFile = $ENV{'expected_file'};
BAIL_OUT("environment variables NOT found")
unless($expectedFile and $seqFile);

my $module;
BEGIN {
	plan tests => 3;
	$module = 'Bio::CUA::CodonTable';
    use_ok( $module ) or 
	BAIL_OUT("Can not load $module");
}

#diag( "Testing Bio::CUA $Bio::CUA::VERSION, Perl $], $^X" );
my $expectedData = _read_data($module);

my $codonTable = $module->new(-id => 1);

# codon_to_aa mapping
my $codonToAA = $codonTable->codon_to_AA_map;
is_deeply($codonToAA,$expectedData->{'codon_to_AA'},"codon and AA map");

# degeneracy
my $codonDegeneracy = $codonTable->codon_degeneracy;
is_deeply($codonDegeneracy, $expectedData->{'degeneracy'},"codon degeneracy");

exit 0;


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

