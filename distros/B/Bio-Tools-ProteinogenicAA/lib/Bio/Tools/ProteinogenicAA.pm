package Bio::Tools::ProteinogenicAA;

use v5.12;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Bio::Tools::ProteinogenicAA::AAInfo;

our $VERSION = '0.021';

has 'aminoacids' => (
	is	=>	'rw',
	isa	=>	'ArrayRef[Bio::Tools::ProteinogenicAA::AAInfo]',
	);

sub BUILD {
	my $self = shift;

	my @list = &create_list;
	$self->aminoacids(\@list);

}

sub create_list {
	
	open ( my $data, '<', 'data/aminoacids.tsv' ) or die;
	my @list;

	while ( my $line = <$data> ) {
		
		next if $line =~ m/^Amino/;
		chomp $line;

		my $aa = Bio::Tools::ProteinogenicAA::AAInfo->new();

		my @info = split (/\,/, $line);
		
		$aa->amino_acid($info[0]);
		$aa->short_name($info[1]);
		$aa->abbreviation($info[2]);
		$aa->pI($info[3]);
		$aa->pK1($info[4]);
		$aa->pK2($info[5]);
		$aa->side_chain($info[6]);
		$info[7] eq 'X' ? $aa->is_hydrophobic(1) : $aa->is_hydrophobic(0);
		$info[8] eq 'X' ? $aa->is_polar(1) : $aa->is_polar(0);
		$aa->pH($info[9]);
		$aa->van_der_waals_volume($info[10]);
		$aa->codons($info[11]);
		$aa->formula($info[12]);
		$aa->monoisotopic_mass($info[13]);
		$aa->avg_mass($info[14]);
		
		push(@list, $aa);

	}
	
	return @list;	
};

1;
