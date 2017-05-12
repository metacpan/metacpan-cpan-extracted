package Bio::CUA::CUB::Builder;

=pod

=head1 NAME

Bio::CUA::CUB::Builder -- A module to calculate codon usage bias (CUB)
metrics at codon level and other parameters

=head1 SYNOPSIS

	use Bio::CUA::CUB::Builder;

	# initialize the builder
	my $builder = Bio::CUA::CUB::Builder->new(
	              codon_table => 1 ); # using stardard genetic code
	
	# calculate RSCU for each codon, and result is stored in "rscu.out" as
	# well as returned as a hash reference
	my $rscuHash = $builder->build_rscu("seqs.fa",undef, 0.5,"rscu.out");

	# calculate CAI for each codon, normalizing RSCU values of codons
	# for each amino acid by the expected RSCUs under even usage,
	# rather than the maximal RSCU used by the traditional CAI method.
	my $caiHash = $builder->build_cai($codonList,2,'mean',"cai.out");

	# calculate tAI for each codon
	my $taiHash = $builder->build_tai("tRNA_copy_number.txt","tai.out", undef, 1);

=head1 DESCRIPTION

Codon usage bias (CUB) can be represented at two levels, codon and
sequence. The latter is often computed as the geometric means of the
sequence's codons. This module caculates CUB metrics at codon level.

Supported CUB metrics include CAI (codon adaptation index), tAI (tRNA 
adaptation index), RSCU (relative synonymous codon usage), and their
variants. See the methods below for details.

The output can be stored in a file which is then used by methods in
L<Bio::CUA::CUB::Calculator> to calculate CUB indice for each
protein-coding sequence.

=cut

use 5.006;
use strict;
use warnings;
use parent qw/Bio::CUA::CUB/;

# paired codon bases for each anticodon base at wobble position.
# According to Crick, FH, 1966, JMB
my %wobbleBasePairsAnti = (
	#Anti => Codon at 3rd position
	A => [qw/T/],
	C => [qw/G/],
	T => [qw/A G/],
	G => [qw/C T/],
	I => [qw/A C T/]
);

# get the version using codon's position as key
sub _build_pairing_anti_base
{
	my $self = shift;
	my %wobbleAntiKey = $self->get_tag('anti_wobble_pair')?
	%{$self->get_tag('anti_wobble_pair')} : %wobbleBasePairsAnti;

	if($self->_a_to_i)
	{
		$wobbleAntiKey{'A'} = $wobbleAntiKey{'I'};
	}
	my %wobbleBasePairs;
	while(my ($antiPos, $codonMatches) = each %wobbleAntiKey)
	{
		foreach (@$codonMatches)
		{
			push @{$wobbleBasePairs{$_}}, $antiPos;
		}
	}
	$self->{'_wobble_pair'} = \%wobbleBasePairs;
}

#default codon selective constraints from dos Reis, et al., 2004 NAR.
# key is anticodon-codon at wobbling site
my %defaultSC = (
	'I-T'	=> 0, # 1
	'A-T'	=> 0,
	'G-C'	=> 0,
	'T-A'	=> 0,
	'C-G'	=> 0, # 5
	'G-T'	=> 0.41,
	'I-C'	=> 0.28,
	'I-A'	=> 0.9999,
	'A-C'	=> 0.28,   # for cases when A is
	'A-A'	=> 0.9999, # regarded as I
	'T-G'	=> 0.68,
	'L-A'	=> 0.89  # 10, L=lysidine present in prokaryotes
);

=head1 METHODS

=head2 new

 Title   : new
 Usage   : $analyzer = Bio::CUA::CUB::Builder->new(-codon_table => 1)
 Function: initiate the analyzer
 Returns : an object
 Args    : accepted options are as follows

 B<options needed for building parameters of all CUB indice>

=over

=item C<-codon_table>

the genetic code table applied for following sequence analyses. It can
be specified by an integer (genetic code table id), an object of
L<Bio::CUA::CodonTable>, or a map-file. See the method
L<Bio::CUA::Summarizer/new> for details.

=back

 B<options needed for building tAI index's parameters>

=over

=item C<-a_to_i>

 a switch option. If true (any nonzero values), all
 'A' nucleotides at the 1st position of anticodon will be regarded as I
 (inosine) which can pair with more nucleotides at codons's wobbling
 position (A,T,C at the 3rd position). The default is true.

=item C<-no_atg>

 a switch option to indicate whether ATG codons should be
 excluded in tAI calculation. Default is true, following I<dos Reis,
 et al., 2004, NAR>. To include ATG in tAI calculation, provide '0' here.

=item C<-wobble>

 reference to a hash containing anticodon-codon basepairs at
 wobbling position, such as ('U' is equivalent to 'T')
 %wobblePairs = (
	A => [qw/T/],
	C => [qw/G/],
	T => [qw/A G/],
	G => [qw/C T/],
	I => [qw/A C T/]
	); # this is the default setting
 Hash keys are the bases in anticodons and hash values are paired
 bases in codons's 3rd positions. This option is optional and default
 value is shown above by the example.

=back

=cut

sub new
{
	my ($caller, @args) = @_;
	my $class = ref($caller)? ref($caller) : $caller;
	my $self = $class->SUPER::new(@args); 

	my $hashRef = $self->_array_to_hash(\@args);
	if(exists $hashRef->{'a_to_i'})
	{
		$self->set_tag('a2i',$hashRef->{'a_to_i'});
	}else
	{
		$self->set_tag('a2i', 1); # true, default
	}
	if(exists $hashRef->{'no_atg'})
	{
		$self->set_tag('no_atg', $hashRef->{'no_atg'});
	}else
	{
		$self->set_tag('no_atg',1); # default is true
	}
	if(exists $hashRef->{'wobble'})
	{
		$self->set_tag('anti_wobble_pair', $hashRef->{'wobble'});
	}

	$self->_build_pairing_anti_base; # make wobble pairing hash
	return $self;
}

# indicator whether A should be regarded as I
sub _a_to_i
{
	my $self = shift;
	$self->get_tag('a2i');
}

=head2 no_atg

 Title   : no_atg
 Usage   : $status = $self->no_atg([$newVal])
 Function: get/set the status whether ATG should be excluded in tAI
 calculation.
 Returns : current status after updating
 Args    : optional. 1 for true, 0 for false

=cut
# implement in parent class Bio::CUA

#=head2 detect_optimal_codons
#
# Title   : detect_optimal_codons
# Usage   : $ok = $self->detect_optimal_codons();
# Function:
# Returns :
# Args    :
#
#=cut

sub detect_optimal_codons
{
	die "detect_optimal_codons has not implemented, yet.$!";
}

=head2 build_rscu

 Title   : build_rscu
 Usage   : $ok = $self->build_rscu($input,[$minTotal,$pseudoCnt,$output]);
 Function: calculate RSCU values for all sense codons
 Returns : reference of a hash using the format 'codon => RSCU value'.
 return undef if failed.
 Args    : accepted arguments are as follows (note: not as hash):

=over

=item C<input>

 name of a file containing fasta CDS sequences of interested
 genes, or a sequence object with method I<seq> to extract sequence
 string, or a plain sequence string, or reference to a hash containing
 codon counts with structure like I<{ AGC => 50, GTC => 124}>.

=item C<output>

 optional, name of the file to store the result. If omitted,
 no result will be written.

=item C<minTotal>

 optional, minimal count of an amino acid in sequences; if observed
 count is smaller than this minimum, all codons of this amino acid would 
 be assigned equal RSCU values. This is to reduce sampling errors in
 rarely observed amino acids. Default value is 5.

=item C<pseudoCnt> 

 optional. Pseudo-counts for unobserved codons. Default is 0.5.

=back

=cut

sub build_rscu
{
	my ($self, $input, $minTotal, $pseudoCnt, $output) = @_;

	$pseudoCnt = 0.5 unless($pseudoCnt and $pseudoCnt > 0);
	$minTotal = 5 unless($minTotal and $minTotal > 0);
	my $codonList = $self->get_codon_list($input) or return;

	my @allAAs = $self->all_AAs_in_table; # get all the amino acids in the codon table
	my %rscu;
	foreach my $AA (@allAAs)
	{
		# get the codons encoding this AA
		my @codons = $self->codons_of_AA($AA);
		my $cntSum = 0; # total observations of this AA's codons
		my $zeroCnt = 0; # number of codons with zero values
		foreach (@codons)
		{
			++$zeroCnt and next unless($codonList->{$_});
			$cntSum += $codonList->{$_};
		}
		# get the rscu values
		if($cntSum < $minTotal) # too small sample
		{
			# assign equal usage to all codons of this amino acid
			foreach (@codons)
			{
				$rscu{$_} = 1/($#codons+1);
			}
		}else
		{
			# add the pseudoCnt correction
			$cntSum += $zeroCnt*$pseudoCnt; 
			foreach (@codons)
			{
				$rscu{$_} = ($codonList->{$_} || $pseudoCnt)/($cntSum || 1);
			}
		}
	}

	$self->_write_out_hash($output, \%rscu) if($output);
	return \%rscu;
}

=head2 build_cai

 Title   : build_cai
 Usage   : $ok = $self->build_cai($input,[$minTotal,$norm_method,$output]);
 Function: calculate CAI values for all sense codons
 Returns : reference of a hash in which codons are keys and CAI values
 are values. return undef if failed.
 Args    : accepted arguments are as follows:

=over

=item C<input>

 name of a file containing fasta CDS sequences of interested
 genes, or a sequence object with method I<seq> to derive sequence
 string, or a plain sequence string, or reference to a hash containing
 codon list with structure like I<{ AGC => 50, GTC => 124}>.

=item C<minTotal>

 optional, minimal codon count for an amino acid; if observed
 count is smaller than this count, all codons of this amino acid would 
 be assigned equal CAI values. This is to reduce sampling errors in
 rarely observed amino acids. Default value is 5.

=item C<norm_method>

 optional, indicating how to normalize RSCU to get CAI
 values. Valid values are 'max' and 'mean'; the former represents the
 original method used by I<Sharp and Li, 1987, NAR>, i.e., dividing
 all RSCUs by the maximum of an amino acid, while 'mean' indicates
 dividing RSCU by expected average fraction assuming even usage of
 all codons, i.e., 0.5 for amino acids encoded by 2 codons, 0.25 for
 amino acids encoded by 4 codons, etc. The CAI metric determined by
 the latter method is named I<mCAI>. mCAI can assign
 different CAI values for the most preferred codons of different
 amino acids, which otherwise would be the same by CAI (i.e., 1).

=item C<output>

 optional. If provided, result will be stored in the file
 specified by this argument.
 
=back

 Note: for codons which are not observed will be assigned a count of
 0.5, and codons which are not degenerate (such as AUG and UGG in
 standard genetic code table) are excluded. These are the default of
 the paper I<Sharp and Li, 1986, NAR>. Here you can also reduce
 sampling error by setting parameter $minTotal.

=cut

sub build_cai
{
	my ($self, $input, $minTotal, $norm, $output) = @_;

	$minTotal = 5 unless(defined $minTotal);
	# get RSCU values first
	my $rscuHash = $self->build_rscu($input,$minTotal,0.5);

	my @AAs = $self->all_AAs_in_table;

	my %cai;
	my $maxCAI = 0; # the maximum value of CAI in this dataset
	foreach my $AA (@AAs)
	{
		my @codons = $self->codons_of_AA($AA);
		# skip non-degenerate codons
		next unless($#codons > 0);

		# determine the factor to normalize the values
		my $scaleFactor;
		if($norm and $norm =~ /mean/i) # normalized by average
		{
			$scaleFactor = $#codons + 1;
		}else # old method, by maximum
		{
			# get the maximum RSCU value for this codon
			my $maxRSCU = 0;
			foreach (@codons)
			{
				my $rscu = $rscuHash->{$_};
				$maxRSCU = $rscu if($maxRSCU < $rscu);
			}
			$scaleFactor = $maxRSCU > 0? 1/$maxRSCU : 0;
		}
		# get CAI values now
		foreach (@codons)
		{
			my $rscu = $rscuHash->{$_};
			$cai{$_} = $rscu*$scaleFactor;
			# global maximum of CAI
			$maxCAI = $cai{$_} if($cai{$_} > $maxCAI);
		}
	}

	#***********************
	# further normalize all CAI by the global maximal CAI, like tAI,
	# but one can opt out this, because without normalize by maxCAI
	# one can distinguish genes more often use less-preferred codons.
	# In this way, value 1 means no bias, > 1 means towards preferred
	# codons while < 1 means towards non-preferred codons
	map { $cai{$_} /= $maxCAI } keys(%cai)
	if($norm and $norm =~ /mean/i and $maxCAI);

	$self->_write_out_hash($output, \%cai) if($output);
	return \%cai;
}

=head2 build_b_cai

 Title   : build_b_cai
 Usage   : $caiHash =
 $self->build_b_cai($input,$background,[$minTotal,$output]);
 Function: calculate CAI values for all sense codons. Instead of
 normalizing RSCUs by maximal RSCU or expected fractions, each RSCU value is
 normalized by the corresponding background RSCU, then these
 normalized RSCUs are used to calculate CAI values.
 Returns : reference of a hash in which codons are keys and CAI values
 are values. return undef if failed.
 Args    : accepted arguments are as follows:

=over

=item C<input>

 name of a file containing fasta CDS sequences of interested
 genes, or a sequence object with metho I<seq> to derive sequence
 string, or a plain sequence string, or reference to a hash containing
 codon list with structure like I<{ AGC => 50, GTC => 124}>.

=item C<background>

 background data from which background codon usage (RSCUs)
 is computed. Acceptable formats are the same as the above argument
 'input'.

=item C<minTotal>

 optional, minimal codon count for an amino acid; if observed
 count is smaller than this count, all codons of this amino acid would 
 be assigned equal RSCU values. This is to reduce sampling errors in
 rarely observed amino acids. Default value is 5.

=item C<outpu>

 optional. If provided, result will be stored in the file
 specified by this argument.

=back

 Note: for codons which are not observed will be assigned a count of
 0.5, and codons which are not degenerate (such as AUG and UGG in
 standard genetic code table) are excluded. 

=cut

sub build_b_cai
{
	my ($self, $input, $background, $minTotal, $output) = @_;

	$minTotal = 5 unless(defined $minTotal);
	# get RSCU values first for input as well as background
	my $rscuHash = $self->build_rscu($input,$minTotal,0.5);
	my $backRscuHash = $self->build_rscu($background,$minTotal,0.5);

	# normalize all RSCU values by background RSCUs
	my @senseCodons = $self->all_sense_codons();
	foreach (@senseCodons)
	{
		$rscuHash->{$_} /= $backRscuHash->{$_};
	}

	# now calculate CAIs for each amino acid
	my @AAs = $self->all_AAs_in_table;

	my %cai;
	my $maxCAI = 0; # the maximum value of CAI in this dataset
	foreach my $AA (@AAs)
	{
		my @codons = $self->codons_of_AA($AA);
		# skip non-degenerate codons
		next unless($#codons > 0);

		# get the maximum RSCU value for this amino acid
		my $maxRSCU = 0;
		foreach (@codons)
		{
			my $rscu = $rscuHash->{$_};
			$maxRSCU = $rscu if($maxRSCU < $rscu);
		}

		# get CAI values now
		foreach (@codons)
		{
			my $rscu = $rscuHash->{$_}; # normalized one
			$cai{$_} = $rscu/$maxRSCU;
		}
	}

	$self->_write_out_hash($output, \%cai) if($output);
	return \%cai;
}

=head2 build_tai

 Title   : build_tai
 Usage   : $taiHash =
 $self->build_tai($input,[$output,$selective_constraints, $kingdom]);
 Function: build tAI values for all sense codons
 Returns : reference of a hash in which codons are keys and tAI indice
 are values. return undef if failed. See Formula 1 and 2 in I<dos
 Reis, 2004, NAR> to see how they are computed.
 Args    : accepted arguments are as follows:
 
=over

=item C<input>

 name of a file containing tRNA copies/abundance in the format
 'anticodon<tab>count' per line, where 'anticodon' is anticodon in
 the tRNA and count can be the tRNA gene copy number or abundance.

=item C<output>

 optional. If provided, result will be stored in the file
 specified by this argument.

=item C<selective_constraints>

 optional, reference to hash containing wobble base-pairing and its
 selective constraint compared to Watson-Crick base-pair, the format
 is like this:
 $selective_constraints = {
                 ...   ...   ...
                 'C-G'   => 0,
				 'G-T'   => 0.41,
				 'I-C'   => 0.28,
				 ...   ...   ...
				 };
 The key follows the 'anticodon-codon' order, and the values are codon
 selective constraints. The smaller the constraint, the stronger the
 pairing, so all Watson-Crick pairings have value 0.
 If this option is omitted, values will be searched for in the 'input' file,
 following the section of anticodons and started with a line '>SC'. If it is
 not in the input file, then the values in the Table 2 of 
 I<dos Reis, 2004, NAR> are used.

=item C<kingdom>

 kingdom = 1 for prokaryota and 0 or undef for eukaryota, which
 affects the cacluation for bacteria isoleucine ATA codon. Default is 
 undef for eukaryota

=back
 
=cut

sub build_tai
{
	my ($self, $input, $output, $SC, $kingdom) = @_;

	# the input copy number of each tRNA
	my $fh = $self->_open_file($input);

	# read into tRNA abundance and if provided, selective constraints
	my %antiCodonCopyNum;
	my %scHash;
	my $metSC = 0;
	while(<$fh>)
	{
		if(/^>SC/) # constraint section
		{
			last if $SC; # provided in this call
			# otherwise record it
			$metSC = 1;
			next;
		}
		chomp;
		my ($k, $v) = split /\s+/;
		$metSC? $scHash{$k} = $v : $antiCodonCopyNum{$k} = $v;
	}
	close $fh;
	$SC ||= \%scHash if(%scHash);
	unless($SC)
	{
		$self->warn("default codon selective constraints (dos Reis) are used")
		if($self->debug);
		$SC = \%defaultSC;
	}

	# now calculate tAI for each codon
	my $allSenseCodons = $self->all_sense_codons;
	my $maxW = 0; # maximum W of all codons
	my %codonWs;
	my $nonzeroWcnt = 0;
	my $nonzeroWsumLog = 0;
	my $excludeATG = $self->no_atg;
	foreach my $codon (@$allSenseCodons)
	{
		# exclude ATG
		next if($excludeATG and $codon eq 'ATG');
		# find its recognizable anticodons
		my $antiCodons = $self->_find_anticodons($codon);
		$self->throw("No anticodons found for codon '$codon'")
		unless($#$antiCodons > 0);
		#print "$codon: ", join(',', @$antiCodons), "\n";
		my $W = 0;
		# this codon may have no anticodons at all, so $W will be 0
		foreach my $anti (@$antiCodons)
		{
			# check whether this tRNA exists here
			next unless(exists $antiCodonCopyNum{$anti});
			# now determine the wobble pair
			my $wobble = substr($anti,0,1).'-'.substr($codon,2,1);
			#my $s = $SC->{$wobble} || 0;
			$self->throw("Unknow wobble '$wobble' pair found")
			unless(exists $SC->{$wobble});
			my $s = $SC->{$wobble};
			$W += (1-$s)*$antiCodonCopyNum{$anti};
		}
		$maxW = $W if($W > $maxW);
		$codonWs{$codon} = $W;
		if($W > 0)
		{
			$nonzeroWcnt++;
			$nonzeroWsumLog += log($W);
		}
		$self->warn("The raw W for codon $codon is 0")
		if($self->debug);
	}

	# geometric mean of non-zero ws
	my $geoMean = exp($nonzeroWsumLog/$nonzeroWcnt)/$maxW;
	# normalize all W values by the max
	while(my ($c, $w) = each %codonWs)
	{
		# assign zero w an geometric mean of other ws
		$codonWs{$c} = $w > 0? $w/$maxW : $geoMean;
	}

	# modify prokaryotic ATA if present
	if($kingdom)
	{
		$codonWs{'ATA'} = (1-$SC->{'L-A'})/$maxW;
	}

	$self->_write_out_hash($output, \%codonWs) if($output);

	return \%codonWs;
}

sub _find_anticodons
{
	my ($self, $codon) = @_;

	my @bases = split //, $codon;
	my $fixedBases = _complement($bases[0])._complement($bases[1]);
	my $wobbleBasePairs = $self->{'_wobble_pair'};
	my $matchAntiBases = $wobbleBasePairs->{$bases[2]};
	my @antiCodons;
	foreach (@$matchAntiBases)
	{
		my $anti = $fixedBases.$_;
		push @antiCodons, scalar(reverse($anti)); # convert to 5'->3'
	}

	return \@antiCodons;
}

sub _complement
{
	my ($base) = @_;

	$base =~ tr/ATCG/TAGC/;

	return $base;
}

=head1 AUTHOR

Zhenguo Zhang, C<< <zhangz.sci at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-cua at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-CUA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::CUA::CUB::Builder


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

1; # End of Bio::CUA::CUB::Builder

