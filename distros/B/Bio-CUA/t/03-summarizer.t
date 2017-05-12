#!perl -T
# test functionality of Bio::CUA::Summarizer
# what to be tested:
# 1. module load correctly
# 2. create object correctly
# 3. test class methods such as bases, sense codons, etc
# 4. read codons from files correctly

use 5.006;
use strict;
use warnings;
use Test::More;
use lib 't';
use env;

#unless ( $ENV{RELEASE_TESTING} ) {
#    plan( skip_all => "Author tests not required for installation" );
#}

# variables
my $expectedFile = $ENV{'expected_file'} 
	or BAIL_OUT("environment variable 'expected_file' NOT found");
my $sep = "\t";


my $module = 'Bio::CUA::Summarizer';
# 1. load module
BEGIN{
	plan tests => 9;

	$module = 'Bio::CUA::Summarizer';
	use_ok($module) or BAIL_OUT("Can not load $module");
}

my @methods = qw/
	codon_table
	bases 
	get_codon_list 
	tabulate_codons
	tabulate_AAs 
	all_sense_codons 
	all_AAs_in_table 
	codons_of_AA
	aa_degeneracy_classes 
	codons_by_degeneracy
	/;

can_ok($module,@methods); # test togther 

# 2. create object
my $sum = $module->new(
					codon_table => 1
				); # using stardard genetic code

isa_ok($sum,$module);

# 3. class methods
my @bases = $sum->bases;
is_deeply(\@bases,[qw/A T C G/],"bases() return");
isa_ok($sum->codon_table, 'Bio::CUA::CodonTable');

# 4. read codons from sequence file
# read into expected results from file
my $expectedCodonCounts = _read_data("$module");
ok($expectedCodonCounts, "read expected data for $module");
ok(-f "t/test.fa", "look for file 't/test.fa'");

# now check the methods by reading a test file
my $codonList = $sum->tabulate_codons('t/test.fa');
is(ref($codonList),'HASH',"tabulate_codons() return");
is_deeply($codonList,$expectedCodonCounts, "codon counts");

exit 0;

# read codon count data from the end
sub _read_data
{
	my $section = shift;

	open(E,"< $expectedFile") 
		or BAIL_OUT("Can not read expected data from $expectedFile");

	my %hash;
	while(<E>)
	{
		next unless /^>>\Q$section\E$/;# find the starting point
		while(<E>)
		{
			last if /^<<\Q$section\E/; # end of the section
			next if /^\s*#/ or /^#/ or /^>/;
			chomp;
			my ($codon, $cnt) = split $sep;
			$hash{$codon} = $cnt;
		}
		last;
	}
	close E;

	return \%hash;
}

