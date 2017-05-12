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
	plan tests => 2;
	$module = 'Bio::CUA::SeqIO';
    use_ok( $module ) or 
	BAIL_OUT("Can not load $module");
}

#diag( "Testing Bio::CUA $Bio::CUA::VERSION, Perl $], $^X" );

my $io = $module->new(-file => $seqFile);
my %lenHash;
while(my $seq = $io->next_seq)
{
	$lenHash{$seq->id} = $seq->length;
}

my $expectedLen = _read_data($module);

# test returned sequence lengths
is_deeply(\%lenHash,$expectedLen,"sequence lengths");

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
		while(<E>)
		{
			last if /^<<\Q$section\E/; # end of the section
			next if /^\s*#/ or /^#/ or /^>/;
			chomp;
			my ($key, $val) = split $sep;
			$hash{$key} = $val;
		}
		last;
	}
	close E;

	return \%hash;
}
