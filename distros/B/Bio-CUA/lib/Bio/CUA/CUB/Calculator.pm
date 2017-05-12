package Bio::CUA::CUB::Calculator;

=pod

=head1 NAME

Bio::CUA::CUB::Calculator -- A module to calculate codon usage bias
(CUB) indice for protein-coding sequences

=head1 SYNOPSIS

	use Bio::CUA::CUB::Calculator;

	my $calc = Bio::CUA::CUB::Calculator->new(
	           -codon_table => 1,
			   -tAI_values  => 'tai.out' # from Bio::CUA::CUB::Builder
			   );

	# calculate tAI for each sequence
	my $io = Bio::CUA::SeqIO->new(-file => "seqs.fa");
	or
	my $io = Bio::CUA::SeqIO->new(-file => "seqs.fa", -format => 'fasta');

	while(my $seq = $io->next_seq)
	{
		my $tai = $calc->tai($seq);
		printf("%10s: %.7f\n", $seq->id, $tai);
	}

=head1 DESCRIPTION

Codon usage bias (CUB) can be represented at two levels, codon and
sequence. The latter is often computed as the geometric means of the
sequence's codons. This module caculates CUB metrics at sequence
level.

Supported CUB metrics include CAI (codon adaptation index), tAI (tRNA
adaptation index), Fop (Frequency of optimal codons), ENC (Effective
Number of Codons) and their variants. See the methods below for
details.

=cut

use 5.006;
use strict;
use warnings;
use parent qw/Bio::CUA::CUB/;
use Bio::CUA::CodonTable;
use Scalar::Util qw/blessed/;

=head1 METHODS

=head2 new

 Title   : new
 Usage   : my $calc=Bio::CUA::CUB::Calculator->new(@args);
 Function: initialize the calculator
 Returns : an object of this class
 Args    : a hash with following acceptable keys:
 
 B<Mandatory options>:

=over

=item C<-codon_table>

 the genetic code table applied for following sequence analyses. It
 can be specified by an integer (genetic code table id), an object of
 L<Bio::CUA::CodonTable>, or a map-file. See the method
 L<Bio::CUA::Summarizer/new> for details.

=back

 B<options needed by FOP method>

=over

=item C<-optimal_codons>

 a file contains all the optimal codons, one codon per line. Or a
 hashref with keys being the optimal codons

=back

 B<options needed by CAI method>

=over

=item C<-CAI_values>

 a file containing CAI values for each codon, excluding 3
 stop codons, so 61 lines with each line containing a codon and its
 value separated by space or tab.
 or
 a hashref with each key being a codon and each value being CAI index
 for the codon.

=back

 B<options needed by tAI method>

=over

=item C<-tAI_values>

 similar to C<-CAI_values>, a file or a hash containing tAI value 
 for each codon.

=back

 B<options needed by ENC method>

=over

=item C<-base_background>

 optional. 
 an arrayref containing base frequency of 4 bases (in the order 
 A,T,C, and G) derived from background data such as introns. 
 Or one of the following values: 'seq', 'seq3', which will lead to
 estimating base frequencies from each analyzed sequence in whol or
 its 3rd codon position, respectively.

 It can also be specified for each analyzed sequence with the methods
 L</encp> and L</encp_r>

=back

=cut

sub new
{
	my ($caller, @args) = @_;

	# option -codon_table is processed in this parent class
	my $self = $caller->SUPER::new(@args);

	# process all the parameters
	my $hashRef = $self->_array_to_hash(\@args);
	while(my ($tag, $val) = each %$hashRef)
	{
		# tag 'codon_table' is now processed by parent package
		if($tag =~ /^optimal/o) # optimal codons
		{
			# a hash using codons as keys
			my $optimalCodons = ref($val) eq 'HASH'? 
			{map { $_ => 1 } keys(%$val)} : $self->_parse_file($val,1);
			$self->{'_optimal_codons'} = $optimalCodons;
		}elsif($tag =~ /^cai/o) # CAI values
		{
			# a hash like codon => CAI_value
			my $caiValues = ref($val) eq 'HASH'? 
			$val : $self->_parse_file($val,2);
			$self->{'_cai_values'} = $caiValues;
		}elsif($tag =~ /^tai/o) # tAI values
		{
			# a hash like codon => tAI_value
			my $taiValues = ref($val) eq 'HASH'?
			$val : $self->_parse_file($val,2);
			$self->{'_tai_values'} = $taiValues;
		}elsif($tag =~ /^base/o) # background base composition
		{
			if(ref($val) eq 'ARRAY' or $val =~ /^seq/)
			{
				$self->{'_base_comp'} = $val;
			}else
			{
				$self->throw("Unknown value '$val' for parameter",
				"-base_background");
			}
		}else
		{
			# Unknown parameter '$tag', ignored
		}
	}

	$self->no_atg(1); # exclude ATG in tAI calculation
	# check the input values
	# 1. make sure all the sense codons have CAI or tAI values if
	# provided

	return $self;
}

=head1 sequence input

all the following methods accept one of the following formats as
sequence input

=over

=item 1
 
 string of nucleotide sequence with length of 3N, 

=item 2

 sequence object which has a method I<seq> to get the sequence string,

=item 3

   a sequence file in fasta format

=item 4

   reference to a codon count hash, like
   $codons = { 
	   AGC => 50, 
       GTC => 124,
	   ...    ...
	   }.

=back

=head2 cai

 Title   : cai
 Usage   : $caiValue = $self->cai($seq);
 Function: calculate the CAI value for the sequence
 Returns : a number, or undef if failed
 Args    : see L</"sequence input">
 Note: codons without synonymous competitors are excluded in
 calculation.

=cut

sub cai
{
	my ($self, $seq) = @_;
	$self->_xai($seq, 'CAI');
}

# the real calculator of tAI or CAI as both have the same formula
sub _xai
{
	my ($self, $seq, $type) = @_;

	my $name;
	my $xaiHash;
	if($type =~ /cai/i)
	{
		$name = 'CAI';
		$xaiHash = $self->{"_cai_values"};
	}elsif($type =~ /tai/i)
	{
		$name = 'tAI';
		$xaiHash = $self->{"_tai_values"};
	}else
	{
		$self->throw("Unknown adaptation index type '$type'");
	}
	unless($xaiHash)
	{
		$self->warn("$name values for codons were not provided for",
		"this analyzer, so can not calculate $name for sequences");
		return undef;
	}

	my $codonList = $self->get_codon_list($seq) or return;

	my $xai = 0;
	my $seqLen = 0; # this excludes some unsuitable codons
	# get non-degenerative codons which are excluded in CAI
	my %nonDegCodons = map { $_ => 1 } $self->codons_by_degeneracy(1);
	my @senseCodons = $self->codon_table->all_sense_codons;
	foreach my $codon (@senseCodons)
	{
		next unless($codonList->{$codon}); # no observation of this codon
		# excluding non-degenerate codons for CAI calculation
		next if($nonDegCodons{$codon} and $type =~ /cai/i);
		unless(exists $xaiHash->{$codon})
		{
			$self->warn("Codon '$codon' is ignored")
			if($self->debug and ($self->no_atg? ($codon ne 'ATG') : 1));
			next;
		}
		my $cnt = $codonList->{$codon};
		# to overcome real number overflow, use log
		$xai += $cnt*log($xaiHash->{$codon});
		$seqLen += $cnt;
	}

	return undef unless($xai); # no codons with CAI/tAI

	$xai = exp($xai/$seqLen);
	return $xai;
}

=head2 fop

 Title   : fop
 Usage   : $fopValue = $self->fop($seq[,$withNonDegenerate]);
 Function: calculate the fraction of optimal codons in the sequence
 Returns : a number, or undef if failed
 Args    : for sequence see L</"sequence input">.
 if optional argument '$withNonDegenerate' is true, then
 non-degenerate codons (those do not have synonymous partners) are
 included in calculation. Default is excluding these codons.

=cut

sub fop
{
	my ($self, $seq, $withNonDeg) = @_;

	my $optimalCodons = $self->{'_optimal_codons'} or 
	$self->throw("No optimal codons associated with $self");

	my $codonList = $self->get_codon_list($seq) or return;
	# get non-degenerate codons
	my %nonDegCodons = map { $_ => 1 } $self->codons_by_degeneracy(1);


	my $optCnt = 0; # optimal codons
	my $total  = 0;
	while(my ($codon, $cnt) = each %$codonList)
	{
		# excluding non-degenerate codons if necessary
		next if(!$withNonDeg and $nonDegCodons{$codon});
		$optCnt += $cnt if($optimalCodons->{$codon});
		$total += $cnt;
	}

	return $optCnt/($total || 1);
}

=head2 tai

 Title   : tai
 Usage   : $taiValue = $self->tai($seq);
 Function: calculate the tAI value for the sequence
 Returns : a number, or undef if failed
 Args    : for sequence see L</"sequence input">.

 Note: codons which do not have tAI values are ignored from input
 sequence

=cut

sub tai
{
	my ($self, $seq) = @_;
	$self->_xai($seq, 'tAI');
}

# an alias
sub tAI
{
	my ($self, $seq) = @_;
	$self->_xai($seq, 'tAI');
}

=head2 enc

 Title   : enc
 Usage   : $encValue = $self->enc($seq,[$minTotal]);
 Function: calculate ENC for the sequence using the original method 
 I<Wright, 1990, Gene>
 Returns : a number, or undef if failed
 Args    : for sequence see L</"sequence input">.
 Optional argument I<minTotal> specifies minimal count 
 for an amino acid; if observed count is smaller than this count, this
 amino acid's F will not be calculated but inferred. Deafult is 5.

 Note: when the F of a redundancy group is unavailable due to lack of
 sufficient data, it will be estimated from other groups following Wright's
 method, that is, F3=(F2+F4)/2, and for others, F=1/r where r is the
 degeneracy degree of that group.

=cut
sub enc
{
	my ($self, $seq, $minTotal) = @_;
	$self->_enc_factory($seq, $minTotal, 'mean');
}

=head2 enc_r

 Title   : enc_r
 Usage   : $encValue = $self->enc_r($seq,[$minTotal]);
 Function: similar to the method L</enc>, except that missing F values
 are estimated in a different way.
 Returns : a number, or undef if failed
 Args    : for sequence see L</"sequence input">.
 Optional argument I<minTotal> specifies minimal count 
 for an amino acid; if observed count is smaller than this count, this
 amino acid's F will not be calculated but inferred. Deafult is 5.

 Note: for missing Fx of degeneracy class 'x', we first estimated the
 ratio (1/Fx-1)/(x-1) by averaging the ratios of other degeneracy
 classes with known F values. Then Fx is obtained by solving the simple
 equation.

=cut

sub enc_r
{
	my ($self, $seq, $minTotal) = @_;
	$self->_enc_factory($seq, $minTotal, 'equal_ratio');
}

=head2 encp

 Title   : encp
 Usage   : $encpValue = $self->encp($seq,[$minTotal,[$A,$T,$C,$G]]);
 Function: calculate ENC for the sequence using the updated method 
 by Novembre I<2002, MBE>, which corrects the  background nucleotide 
 composition.
 Returns : a number, or undef if failed
 Args    : for sequence see L</"sequence input">.
 
 Optional argument I<minTotal> specifies minimal count 
 for an amino acid; if observed count is smaller than this count, this
 amino acid's F will not be calculated but inferred. Deafult is 5.

 another optional argument gives the background nucleotide composition
 in the order of A,T,C,G in an array, if not provided, it will use the
 default one provided when calling the method L</new>. If stil
 unavailable, error occurs.

=cut

sub encp
{
	my ($self, $seq, $minTotal, $baseComp) = @_;
	$self->_enc_factory($seq, $minTotal, 'mean', 1, $baseComp);
}

=head2 encp_r

 Title   : encp_r
 Usage   : $encpValue =
 $self->encp_r($seq,[$minTotal,[$A,$T,$C,$G]]);
 Function: similar to the method L</encp>, except that missing F values
 are estimated using a different way.
 Returns : a number, or undef if failed
 Args    : for sequence see L</"sequence input">.
 
 Optional argument I<minTotal> specifies minimal count 
 for an amino acid; if observed count is smaller than this count, this
 amino acid's F will not be calculated but inferred. Deafult is 5.

 another optional argument gives the background nucleotide composition
 in the order of A,T,C,G in an array, if not provided, it will use the
 default one provided when calling the method L</new>. If stil
 unavailable, error occurs.

 Note: for missing Fx of degeneracy class 'x', we first estimated the
 ratio (1/Fx-1)/(x-1) by averaging the ratios of other degeneracy
 classes with known F values. Then Fx is obtained by solving the simple
 equation.

=cut

sub encp_r
{
	my ($self, $seq, $minTotal, $baseComp) = @_;
	$self->_enc_factory($seq, $minTotal, 'equal_ratio', 1, $baseComp);
}

# real function calculate different versions of ENC
# parameters explanation
# seq: sequence string, sequence object, sequence file, or hash
# reference to codon list
# correctBaseComp: if true, correct background base composition using
# Novembre's method
# F_EstimateMethod: how to estimate average F for a certain redundancy
# class if that class does not have observed data so can't be
# calculated; 'mean' is for Wright's method, and 'equal_ratio' for
# Zhenguo's method. The latter assumes a similar (1/F[r])/r for each
# redundancy class with redundancy degree 'r'
# baseComposition: optional, a reference to an array containing
# background nucleotide composition. If provided, it overides the
# values set when method L</new> was called.
sub _enc_factory
{
	my ($self, $seq, $minTotal, $F_EstimateMethod, $correctBaseComp, $baseComposition) = @_;

	$minTotal = 5 unless(defined $minTotal); # the minumum count of residule for a given amino
	# acid for it to be included in F calculation
	
	# a hash ref, codon => counts
	my $codonList = $self->get_codon_list($seq) or return;
	my $seqId = (blessed($seq) and $seq->can('id'))? $seq->id : '';

	# determine expected codon frequency if necessary
	my $expectedCodonFreq;
	# determine base compositions now
	if($correctBaseComp)
	{
		if(!defined($baseComposition)) # not provided for this sequence
		{
			my $defaultBaseComp = $self->base_composition;
			unless($defaultBaseComp)
			{
				$self->warn("No default base composition for seq",
				" '$seqId', so no GC-corrected ENC");
				return undef;
			}
			if($defaultBaseComp eq 'seq')
			{
				$baseComposition =
				$self->estimate_base_composition($codonList);
			}elsif($defaultBaseComp eq 'seq3')
			{
				$baseComposition =
				$self->estimate_base_composition($codonList,3);
			}else
			{
				$baseComposition = $defaultBaseComp;
			}
		} # otherwise sequence-specific base-composition is provided
		# here

		# codon frequency may not be estimated due to invalid
		# compositions
		$expectedCodonFreq =
		$self->expect_codon_freq($baseComposition) 
		if($baseComposition);
		return undef unless($expectedCodonFreq);
	}


	# now let us calculate F for each redundancy class
	# determined by codon table, containing all amino acid classes
	my $AARedundancyClasses = $self->aa_degeneracy_classes; #
	my %FavgByClass; # record the average F from each class
	while(my ($redundancy, $AAHash) = each %$AARedundancyClasses)
	{
		# number of observed AA types in this class
		my $numAAInClass = 0; # number of amino acid species in this class
		my $Fsum = 0;
		while(my ($AA, $codonArray) = each %$AAHash)
		{
			if($redundancy == 1) # this class has only one codon
			{
				$numAAInClass = scalar(keys %$AAHash);
				$Fsum = $numAAInClass; # each AA contribute 1
				last;
			}
			# total count of observed residules for this AA
			my $AAcnt = 0; 
			foreach (@$codonArray)
			{
				# check the codon exists in this seq
				next unless(exists $codonList->{$_});
				$AAcnt += $codonList->{$_};
			}
			
			# skip if occurence of this amino acid is less than the
			# minimal threshold
			next if($AAcnt < $minTotal or $AAcnt < 2);

			# now calculate F for this AA species
			if($correctBaseComp) # correct base composition
			{
				my $chisq = 0;
				# get the freq of codons of this amino acids
				my $totalFreq = 0;
				foreach (@$codonArray)
				{
					$totalFreq += $expectedCodonFreq->{$_};
				}
				foreach (@$codonArray)
				{
					# set unobserved codons to 0
					my $codonCnt = $codonList->{$_} || 0;
					my $expectedFreq =
					$expectedCodonFreq->{$_}/$totalFreq;
					$chisq += ($codonCnt/$AAcnt -
						$expectedFreq)**2/$expectedFreq;
				}
				$chisq *= $AAcnt; # don't forget multiply this
				$Fsum += ($chisq + $AAcnt -
					$redundancy)/($redundancy*($AAcnt-1));
			}else # no correction, use old Wright method
			{
				my $pSquareSum = 0;
				foreach (@$codonArray)
				{
					my $codonCnt = $codonList->{$_};
					next unless($codonCnt);
					$pSquareSum += ($codonCnt/$AAcnt)**2;
				}
				$Fsum += ($AAcnt*$pSquareSum -1)/($AAcnt-1);
			}
			# increase the number of AA species in this class
			$numAAInClass++;
		}
		# check whether all AA species are ignored or not observed
		if($numAAInClass > 0)
		{
			# note, in some special cases, Fsum == 0 even though
			# $numAAInClass >0, for example for a 6-fold amino acid,
			# if each of its codon is observed only once, it would
			# result in Faa = 0. so we need add restriction on this
			$FavgByClass{$redundancy} = $Fsum/$numAAInClass if($Fsum >
				0);
		} # otherwise no data
	}

	# estimate missing redundancy classes due to no observation of
	# that class's AAs, and get the final Nc values
	my $enc = 0;
	while(my ($redundancy, $AAHash) = each %$AARedundancyClasses)
	{
		# the number of AA species in this class, determined by the
		# codon table, not the input seq
		my $AAcntInClass = scalar(keys %$AAHash);
		if(exists $FavgByClass{$redundancy})
		{
			die "$redundancy, $AAcntInClass in seq '$seqId':$!"
			unless($FavgByClass{$redundancy});
			$enc += $AAcntInClass/$FavgByClass{$redundancy};
			next;
		}

		# otherwise this class was not observed
		my $equalRatio = $F_EstimateMethod eq 'mean'? 0 : 1;
		my $estimatedFavg = _estimate_F(\%FavgByClass, $redundancy,
			$equalRatio);
		unless($estimatedFavg)
		{
			$self->warn("Cannot estimate average F for class with",
				"redundancy=$redundancy in sequence $seqId, ", 
				"probably no known F values for any class");
			return undef;
		}
		$enc +=  $AAcntInClass/$estimatedFavg;
	}

	return $enc;
}

# estimate F average
sub _estimate_F
{
	my ($knownF,$redundancy,$equalRatio) = @_;

	return 1 if($redundancy == 1);

	if($equalRatio) # get the mean (1/Fr-1)/(r-1)
	{
		my $ratioSum;
		my $cnt = 0; # number of known Fs
		while(my ($r, $F) = each %$knownF)
		{
			next if $r < 2; # excluding class of redundancy==1
			$ratioSum += (1/$F-1)/($r-1);
			$cnt++;
		}

		if( $cnt > 0)
		{
			my $Fx = 1/($ratioSum/$cnt*($redundancy-1)+1);
			return $Fx;
		}else # no known F for any class with redundancy > 1
		{
			return undef;
		}

	}else # otherwise use Wright's method
	{
		if($redundancy == 3)
		{
			my $F2 = $knownF->{2} || 1/2; # class 2
			my $F4 = $knownF->{4} || 1/4; # class 4
			return ($F2 + $F4)/2;
		}else
		{
			return 1/$redundancy; # assuming no bias
		}
	}

}

# get the default base compostion of this object
sub base_composition
{
	my $self = shift;

	return $self->{'_base_comp'};
}

=head2 estimate_base_composition

 Title   : estimate_base_composition
 Usage   : @baseComp = $self->estimate_base_composition($seq,[$pos])
 Function: estimate base compositions in the sequence
 Returns : an array of numbers in the order of A,T,C,G, or its
 reference if in the scalar context
 Args    : a sequence string or a reference of hash containing codons
 and their counts (eg., AGG => 30), and optionally an integer; the integer
 specifies which codon position's nucleotide will be used instead of
 all three codon positions.

=cut

sub estimate_base_composition
{
	my ($self, $seq, $pos) = @_;

	my %bases;
	# check if input is a codon list
	my $codonList;
	if(ref($seq) eq 'HASH') # a codon list
	{
		$codonList = $seq;
	}else # a sequence string or object
	{
		$seq = $self->_get_seq_str($seq);
	}

	if($pos)
	{
		$self->throw("Only 1, 2, or 3 are acceptable for pos,",
			"'$pos' is not valid here") unless($pos > 0 and $pos < 4);
		if($codonList) # input is a codon list
		{
			my $base;
			while(my ($codon, $cnt) = each %$codonList)
			{
				$base = substr($codon, $pos-1,1);
				$bases{$base} += $cnt;
			}
		}else # a sequence
		{
			my $seqLen = length($seq);
			my $accuLen = $pos - 1;
			my $period = 3; # a codon length
			my $base;
			while($accuLen < $seqLen)
			{
				$base = substr($seq,$accuLen,1);
				$bases{$base}++;
				$accuLen += $period;
			}
		}
	}else # all nucleotides
	{
		if($codonList) # input is a codon list
		{
			while(my ($codon, $cnt) = each %$codonList)
			{
				map { $bases{$_} += $cnt } split('', $codon);
			}
		}else
		{
			map { $bases{$_}++ } split('',$seq);
		}
	}

	my $total = 0;
	my @comp;
	foreach ($self->bases) # only consider A,T,C,G
	{
		$total += $bases{$_} || 0;
		push @comp, $bases{$_} || 0;
	}
	@comp = map { $_/$total } @comp;

	return wantarray? @comp : \@comp;
}

=head2 gc_fraction

 Title   : gc_fraction
 Usage   : $frac = $self->gc_fraction($seq,[$pos])
 Function: get fraction of GC content in the sequence
 Returns : a floating number between 0 and 1.
 Args    : a sequence string or a reference of hash containing codons
 and their counts (eg., AGG => 30), and optionally an integer; the integer
 specifies which codon position's nucleotide will be used for
 calculation (i.e., 1, 2, or 3), instead of all three positions.

=cut

sub gc_frac
{
	my ($self, @args) = @_;
	$self->gc_fraction(@args);
}

sub gc_fraction
{
	my ($self, @args) = @_;

	my @composition = $self->estimate_base_composition(@args);
	my @bases = $self->bases;
	my @indice = grep { $bases[$_] =~ /[GC]/ } 0..$#bases;

	my $frac = 0;
	foreach (@indice)
	{
		$frac += $composition[$_];
	}

	return $frac;
}

=head2 expect_codon_freq

 Title   : expect_codon_freq
 Usage   : $codonFreq = $self->expect_codon_freq($base_composition)
 Function: return the expected frequency of codons
 Returns : reference to a hash in which codon is hash key, and
 fraction is hash value
 Args    : reference to an array of base compositions in the order of
 [A, T, C, G], represented as either counts or fractions

=cut

sub expect_codon_freq
{
	my ($self, $baseComp) = @_;

	unless($baseComp and ref($baseComp) eq 'ARRAY')
	{
		$self->warn("Invalid base composition '$baseComp'",
		" for expect_codon_freq, which should be an array reference");
		return undef;
	}

	my @bases = $self->bases;
	my $compSum = 0; # used to normalize in case they are not summed to 1
	my $zeroCnt = 0; # count of zero values
	foreach (0..3)
	{
		$zeroCnt++ if($baseComp->[$_] == 0);
		$compSum += $baseComp->[$_];
	}

	# set zero value a pseudo count, depending on the provided values
	# are fractions or counts
	my $pseudoCnt = $compSum > 2? 1 : 1/100;
	$compSum += $pseudoCnt * $zeroCnt;
	my %freq = map { $bases[$_] => ($baseComp->[$_] || $pseudoCnt)/$compSum } 0..3;
	my %result;
	foreach my $b1 (@bases)
	{
		foreach my $b2 (@bases)
		{
			foreach my $b3 (@bases)
			{
				my $codon = $b1.$b2.$b3;
				$result{$codon} = $freq{$b1}*$freq{$b2}*$freq{$b3};
			}
		}
	}

	return \%result;
}

=head1 AUTHOR

Zhenguo Zhang, C<< <zhangz.sci at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-cua at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-CUA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::CUA::CUB::Calculator


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

1; # End of Bio::CUA::CUB::Calculator
