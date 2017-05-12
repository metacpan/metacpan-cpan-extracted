package Bio::CUA::Summarizer;

use 5.006;
use strict;
use warnings;
use parent qw/Bio::CUA/;
use Bio::CUA::CodonTable;

my $codonPkg = 'Bio::CUA::CodonTable';
my $pkg = __PACKAGE__;
my @bases = qw/A T C G/;

# determine which class is used for sequence processing
my $seq_io_pkg;
BEGIN{
	# set version which might be checked during compilation
	#our $VERSION = 1.01;

	# determine sequence processing module
	eval { require Bio::SeqIO; };
	if($@) # Bio::SeqIO is not available
	{
		$seq_io_pkg = 'Bio::CUA::SeqIO';
		require Bio::CUA::SeqIO;
	}else # otherwise use Bio::SeqIO
	{
		$seq_io_pkg = 'Bio::SeqIO';
	}
}

=pod

=head1 NAME

Bio::CUA::Summarizer - a class to summarize features of sequences.

=head1 SYNOPSIS

This class provides convenience for its child classes with methods
summarizing sequence features, such
as counting and listing amino acids and codons, retrieving amino acids
with certain degree degeneracy in a genetic table. Refer to the
L</Methods> section for more details.

	use Bio::CUA::Summarizer;

	my $summarizer = Bio::CUA::Summarizer->new(
	                 codon_table => 1 ); # using stardard genetic code
	
	# get codons in a sequence file
	my $codonList = $summarizer->tabulate_codons('seqs.fa');
	# get the codon table object of this summarizer
	my $table = $summarizer->codon_table;
	# get all sense codons in the genetic codon table
	my @senseCodons = $summarizer->all_sense_codons;
	# get codons encoding an amino acid
	my @codons = $summarizer->codons_of_AA('Ser');

=cut


=head2 new

 Title   : new
 Usage   : $obj=Bio::CUA::Summarizer->new(%args);
 Function: create an object which can be used to summarizing sequence
 features.
 Returns : an object of this or child class
 Args    : a hash with a key 'codon_table', acceptable values are
  codon_table => id of genetic codon table # 1
  codon_table => Bio::CUA::CodonTable object # 2
  codon_table => 'map-file' # 3

=over 3

=item 1

id of genetic codon table can be found from L<NCBI genetic
codes|http://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?mode=t>.
A valid id is an integer.

=item 2

an object of L<Bio::CUA::CodonTable>. One can directly provide an
object to the method.

=item 3

If genetic code in analyzed sequences is not included in NCBI, one can
also provide its own genetic code in a map-file, in the format of
codon1<tab>AA1
codon2<tab>AA2,
... ... ....

=back

Note all the analyzed sequences will use this provided genetic codon
table to map between amino acids and codons.

=cut

sub new
{
	my ($caller, @args) = @_;
	my $self = $caller->SUPER::new(@args);

	my $hashRef = $self->_array_to_hash(\@args);

	# only process its own argument
	my $codonTable;
	while(my ($tag, $val) = each %$hashRef)
	{
		next unless($tag eq 'codon_table');
		if(ref($val))
		{
			$self->throw("$val is not an object of $codonPkg")
			unless($val->isa($codonPkg));
			$codonTable = $val;
		}elsif($val =~ /^\d+$/) # genetic code id
		{
			$codonTable = $codonPkg->new(-id => $val) or
			$self->throw("Invalid genetic code ID '$val'");
		}else # a map file
		{
			$codonTable = $codonPkg->new(-map_file => $val) or
			$self->throw("Can not construct codon table with file '$val'");
		}
		last;
	}
	$self->warn("option 'codon_table' is missing in the method", 
		"'new' of $pkg") and return undef unless($codonTable);
	# store the result
	$self->{'_codon_table'} = $codonTable;

	return $self;
}

=head2 codon_table

 Title   : codon_table
 Usage   : $table = $self->codon_table;
 Function: get associated codon table of this object
 Returns : an object of L<Bio::CUA::CodonTable>
 Args    : None

=cut

sub codon_table
{
	my $table = $_[0]->{'_codon_table'} or
	$_[0]->warn("No codon table associated with this object $_[0]");
	return $table;
}

=head2 bases

get the 4 nucleotides A,T,C,G always in this order, to keep
consistency among different classes

=cut

# get all the nucleotide bases in a certain order
sub bases
{
	return wantarray? @bases : \@bases;
}

# sequence-level functions
=head2 get_codon_list

 Title   : get_codon_list
 Usage   : $codonList = $self->get_codon_list($input)
 Function: get codons and their counts in input
 Returns : reference to a hash containing codons as keys and counts
 as values.
 Args    : seq string, seq object, seq file, or another codon list

=cut

# the main interface to preprocess input to most methods
# return a codon list with its count
# acceptable parameters: seq string, seq object, seq file, codon list
sub get_codon_list
{
	my ($self, $input) = @_;

	my $ref = ref($input);
	unless($ref) # a scalar variable
	{
		# a sequence string
		if($input =~ /^[ATGCUN]+$/ and (! -f $input))
		{
			return $self->_catalog_codons($input);
		}else # a sequence file
		{
			return $self->tabulate_codons($input);
		}
	}

	if($ref eq 'HASH') # codon list
	{
		return $input;
	}else # an seq object
	{
		return $self->_catalog_codons($input);
	}
}

=head2 tabulate_codons

 Title   : tabulate_codons
 Usage   : $codonList = $self->tabulate_codons($input,[$each]);
 Function: count codons in the input sequences
 Returns : reference to a hash in which codon is the key and counts as
 values. If $each is true, then each sequence is separately processed
 and stored in a larger hash. The count of a codon in a sequence can
 be retrieved like this: $codonList->{'seqId'}->{'codon'}.
 Args    : accepted arguments are as follows:
 I<input> = name of a file containing fasta sequences
 I<each>  = optional, if TRUE (i.e., non-zero values), each sequence is
 separately processed.

This is a companionate method of L</get_codon_list> for situations
when one want to get codon counts for each sequence separately.

=cut

sub tabulate_codons
{
	my ($self, $input, $each) = @_;

	my $seqIO = $self->_get_seq_io($input) or return;
	my %list;

	if($each)
	{
		while(my $seq = $seqIO->next_seq())
		{
			my $codons = $self->_catalog_codons($seq->seq);
			$list{$seq->id} = $codons;
		}

	}else # otherwise process together
	{
		while(my $seq = $seqIO->next_seq())
		{
			my $codons = $self->_catalog_codons($seq->seq);
			# merge all codons together
			while(my ($c, $v) = each %$codons)
			{
				$list{$c} += $v;
			}
		}
	}
	
	return undef unless(keys %list);
	return \%list;
}

=head2 tabulate_AAs

 Title   : tabulate_AAs
 Usage   : $AAList = $self->tabulate_AAs($input,[$each]);
 Function: similar to L</tabulate_codons>, but for counting amino acids
 Returns : the same as L</tabulate_codons>, but for amino acids
 Args    : refer to L</tabulate_codons>.

=cut

sub tabulate_AAs
{
	my ($self, $input, $each) = @_;

	my $codonList = $self->tabulate_codons($input) or return;

	my %AAs;
	if($each)
	{
		while(my ($id, $hashRef) = each %$codonList)
		{
			while(my ($codon, $count) = each %$codonList)
			{
				my $AA = $self->_codon_to_aa($codon) or next;
				$AAs{$id}->{$AA} += $count;
			}
		}
	}else
	{
		while(my ($codon, $count) = each %$codonList)
		{
			my $AA = $self->_codon_to_aa($codon) or next;
			$AAs{$AA} += $count;
		}
	}

	return \%AAs;
}

# get the sequence IO and return it
sub _get_seq_io
{
	my ($self, $input) = @_;

	$self->warn("input fasta file is needed to obtain seq IO") and return
	unless($input);
	# at present, use Bio::SeqIO
	my $io = $seq_io_pkg->new(-file => $input, -format => 'fasta');
	return $io;
}


# codon table functions
=head2 all_sense_codons

get all sense codons in the genetic codon table of this object

=cut

sub all_sense_codons
{
	my ($self) = @_;

	my $codonTable = $self->codon_table() or return;

	return $codonTable->all_sense_codons;
}

=head2 all_AAs_in_table

get all the amino acids coded in the genetic code table of this object

=cut

sub all_AAs_in_table
{
	my ($self) = @_;

	my $codonTable = $self->codon_table() or return;

	$codonTable->all_amino_acids();
}

=head2 codons_of_AA

get codons coding the given amino acid, I<e.g.>,

	my @codons = $self->codons_of_AA('Ser');

=cut

sub codons_of_AA
{
	my ($self, $AA) = @_;

	my $codonTable = $self->codon_table() or return;

	return $codonTable->codons_of_AA($AA);
}

=head2 aa_degeneracy_classes

 Title   : aa_degeneracy_classes
 Usage   : $hashRef = $self->aa_degeneracy_classes;
 Function: get amino acid degeneracy classes according to the
 associated genetic code table
 Returns : a hash reference in which first level key is degeneracy
 degrees such as 1,2,3,4,6, second level is amino acid, the value is
 reference to the corresponding codon array. For example:
 
 { 2 => { D => [GAU, GAC],
          C => [UGU, UGC],
		  ...  ...
 		},
   4 => { A => [GCU, GCC, GCA, GCG],
          ...  ...
        },
	...  ...  ...
 }

 Args    : None

=cut

sub aa_degeneracy_classes
{
	my $codonTable = $_[0]->codon_table or return;
	return $codonTable->codon_degeneracy;
}

=head2 codons_by_degeneracy

 Title   : codons_by_degeneracy
 Usage   : @codons = $self->codons_by_degeneracy(2);
 Function: get all the codons of AAs which have the specified degree
 of degeneracy, for example, codons of amino acids with degenracy
 degree 2.
 Returns : an array of codons, or its reference in scalar context
 Args    : an integer for degeneracy degree

=cut

sub codons_by_degeneracy
{
	my ($self, $deg) = @_;
	my $degHash = $self->aa_degeneracy_classes or return;
	my $aaClass = $degHash->{$deg} or return;
	my @codons;
	while(my ($aa, $codonRef) = each %$aaClass)
	{
		push @codons, @$codonRef;
	}
	return wantarray? @codons : \@codons;
}

# other misc functions
#############################################
# Other methods used internally
#############################################

# check whether a codon is valid and also not stop codon
sub _is_sense_codon
{
	my ($self, $codon) = @_;

	my $codonTable = $self->codon_table() or return;
	return 0 unless($codonTable->is_valid_codon($codon));
	return 0 if($codonTable->is_stop_codon($codon));

	return 1;
}

# check whether a codon is a stop codon
sub _is_stop_codon
{
	my ($self, $codon) = @_;
	my $codonTable = $self->codon_table() or return;
	$codonTable->is_stop_codon($codon);
}

# get the corresponding AA of a codon
sub _codon_to_aa
{
	my ($self, $codon) = @_;

	my $codonTable = $self->codon_table() or return;
	$codonTable->translate($codon);
}

# get all the codons in the sequence, that is, split into nucleotide
# triplet
sub _catalog_codons
{
	my ($self, $seq) = @_;

	$seq = $self->_get_seq_str($seq);
	my %codons;
	my $accuLen = 0;
	my $seqLen = length($seq);
	$self->warn("sequence [$seq] is not multiple of 3 long") unless($seqLen %
		3 == 0);
	my $codon;
	while($accuLen + 3 <= $seqLen)
	{
		$codon = substr($seq,$accuLen,3);
		$codons{$codon}++;
		$accuLen += 3;
	}

	return undef unless($accuLen);
	return \%codons;
}

# get and preprocess sequence
# get a seq string or seq object and return sequence string
sub _get_seq_str
{
	my ($self, $seq) = @_;
	$seq = ref($seq)? $seq->seq : $seq;
	$seq = uc($seq);
	$seq =~ tr/U/T/;
	$seq =~ s/[^A-Z]+//g; # remove all non-nucleotide characters

	my $len = length($seq);
	if($len > 0)
	{
		return $seq;
	}else
	{
		return undef;
	}
}

=head1 AUTHOR

Zhenguo Zhang, C<< <zhangz.sci at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-cua at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-CUA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::CUA::Summarizer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-CUA>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-CUA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-CUA>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-CUA/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Zhenguo Zhang.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

1; # End of Bio::CUA::Summarizer

