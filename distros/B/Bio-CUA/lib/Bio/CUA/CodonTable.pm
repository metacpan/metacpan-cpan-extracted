package Bio::CUA::CodonTable;

=pod

=head1 NAME

Bio::CUA::CodonTable -- A package processing genetic codon table

=head1 SYNOPSIS

This package is provided to improve portability of
L<http://search.cpan.org/dist/Bio-CUA/>, in case that one may not 
install L<BioPerl/http://www.bioperl.org/> which includes huge number 
of modules.

The package obtains genetic code tables from NCBI at
L<http://www.ncbi.nlm.nih.gov/Taxonomy/taxonomyhome.html/index.cgi?chapter=cgencodes>

examples:

	# get the standard genetic code
    my $table = Bio::CUA::CodonTable->new(-id => 1)

	# get table from an input file if know genetic codes can not
	# satisfy the need.
	my $table = Bio::CUA::CodonTable->new(-map_file =>
	'codon_to_aa.tsv')
	# in 'codon_to_aa.tsv', it looks like this
	# GCU	A
	# AAU	N
	# CAU	H
	# ...   ...

=cut

use 5.006;
use strict;
use warnings;
use parent qw/Bio::CUA/;

# global variables
my $pkg = __PACKAGE__;
my $STOPAA = '*';
my %validGCIds = map { $_ => 1 } (1..6,9..14,16,21..25); # in future this can be derived
# from data section at the end

=head2 new

 Title   : new
 Usage   : $obj = Bio::CUA::CodonTable->new(-map_file => 'file');
 Function: creat an object for processing genetic codon tables
 Returns : an object of L<Bio::CUA::CodonTable>
 Args    : a hash with following keys:

=over 4

=item -id

 genetic code id. The id follows NCBI's standard, here are
 the list:
  1. The Standard Code
  2. The Vertebrate Mitochondrial Code
  3. The Yeast Mitochondrial Code
  4. The Mold, Protozoan, and Coelenterate Mitochondrial Code and
     the Mycoplasma/Spiroplasma Code
  5. The Invertebrate Mitochondrial Code
  6. The Ciliate, Dasycladacean and Hexamita Nuclear Code
  9. The Echinoderm and Flatworm Mitochondrial Code
  10. The Euplotid Nuclear Code
  11. The Bacterial, Archaeal and Plant Plastid Code
  12. The Alternative Yeast Nuclear Code
  13. The Ascidian Mitochondrial Code
  14. The Alternative Flatworm Mitochondrial Code
  16. Chlorophycean Mitochondrial Code
  21. Trematode Mitochondrial Code
  22. Scenedesmus obliquus Mitochondrial Code
  23. Thraustochytrium Mitochondrial Code
  24. Pterobranchia Mitochondrial Code
  25. Candidate Division SR1 and Gracilibacteria Code
  see
  L<http://www.ncbi.nlm.nih.gov/Taxonomy/taxonomyhome.html/index.cgi?chapter=tgencodes#SG1>
  for more details.

=item -map_file

 -map_file = a file containing a mapping between codons to amino
 acids, one codon per line followed by its amino acid, separated by
 tab or space.

=item -debug

 a switch to indicate whether to show more warnings which may
 help to identify sources of errors if any. put 1 to switch
 it on. The default is off.

=back

  Note: argument -map_file has higher priority than -id, and the
  default is -id => 1, i.e., the standard genetic code

=cut

sub new
{
	my ($caller, @args) = @_;

	my $self = $caller->SUPER::new(@args);

	my $hash = $self->_array_to_hash(\@args);

	if($hash->{'map_file'})
	{
		$self->_build_table_by_file($hash->{'map_file'});
	}elsif($hash->{'id'})
	{
		$self->_build_table_by_id($hash->{'id'});
	}else
	{
		$self->warn("No arguments -map_file or -id is provided in",
			"$pkg, -id => 1 will be used") if($self->debug);
		$self->_build_table_by_id(1);
	}

	return $self;
}

# get genetic code table by parsing a file
sub _build_table_by_file
{
	my ($self, $file) = @_;

	my $codonToAA = $self->_parse_file($file,2);

	# check all the codons and amino acids
	my %validCodons;
	my %stopCodons;
	while(my ($codon, $AA) = each %$codonToAA)
	{
		$codon = _process_codon($codon);
		($self->warn("$codon is Not a valid codon") and next)
		unless($codon =~ /^[ATCG]{3}$/);
		$validCodons{$codon} = $AA;
		$stopCodons{$codon}++ if($self->_is_stop_aa($AA));
	}

	$self->{'_codon_to_aa'} = \%validCodons;
	$self->{'_stop_codons'} = \%stopCodons;
	my $totalCodonNum = scalar(keys %validCodons);
	$self->{'_num_codons'} = $totalCodonNum;
	if($totalCodonNum < 64)
	{
		$self->warn("Only $totalCodonNum valid codons found in '$file'");
	}

	return 1;
}

# make codon table with given table ID
sub _build_table_by_id
{
	my ($self, $id) = @_;

	$self->throw("Id '$id' is not a valid genetic code table Id")
	unless($self->_is_valid_gc_id($id));

	#my $curFile = __FILE__;
	#warn "I am in $curFile\n";

	my $fh = $self->_open_file(__FILE__);

	my $inDataSection = 0;
	my $inGCSection = 0; # genetic codon section
	my $data = '';
	# cut the genetic codon section first
	while(<$fh>)
	{
		$inDataSection = 1 if(/^__END__/);
		next unless($inDataSection);
		last if(/^<<GC/); # end of the section
		$inGCSection = 1 if(/^>>GC/);
		next if(/^>/ or /^--/); # comment lines
		$data .= $_;
	}
	close $fh;

	# match each table and find that with the id = $id
	my $table;
	while($data =~ /\n *{ *\n *(name[^}]+)}/gcm)
	{
		$table = $1;
		next unless($table =~ /^ *id\s+$id\s*,/m);
		last; # found
	}

	# now parse this table
	my %codonToAA;
	my %stopCodons;
	my %startCodons;
	my ($b1) = $table =~ /^ *-- +Base1 +(\w+)/mo;
	my ($b2) = $table =~ /^ *-- +Base2 +(\w+)/mo;
	my ($b3) = $table =~ /^ *-- +Base3 +(\w+)/mo;
	my ($AAs) = $table =~ /^ *ncbieaa +"([^"]+)"/mo;
	$AAs =~ s/\s+//g;
	my ($starts) = $table =~ /^ *sncbieaa +"([^"]+)"/mo;
	$starts =~ s/\s+//g;
	my @names;
	while($table =~ /^ *name +("[^"]+")/mgco)
	{
		my $name = $1;
		$name =~ s/\n/ /g;
		push @names, $name;
	}

	$self->warn("The length of lines in genetic table $id is not 64")
	unless(length($b1) == 64);
	$self->throw("lines of bases and amino acids are not the same long", 
		"in genetic table $id") 
	unless( length($b1) == length($b2) and
		    length($b1) == length($b3) and
			length($b1) == length($AAs) and
			length($b1) == length($starts));

	$self->set_tag('name', join(' or ', @names));
	$self->set_tag('id', $id);
	for(my $i = 0; $i < length($b1); $i++)
	{
		my $nt1 = substr($b1, $i, 1);
		my $nt2 = substr($b2, $i, 1);
		my $nt3 = substr($b3, $i, 1);
		my $AA  = substr($AAs, $i, 1);
		my $start = substr($starts, $i, 1);
		my $codon = uc($nt1.$nt2.$nt3);
		$codonToAA{$codon} = $AA;
		$stopCodons{$codon}++ if($self->_is_stop_aa($AA));
		$startCodons{$codon}++ unless($start eq '-');
	}

	$self->{'_codon_to_aa'} = \%codonToAA;
	$self->{'_stop_codons'} = \%stopCodons;
	$self->{'_start_codons'} = \%startCodons;
	$self->{'_num_codons'} = scalar(keys %codonToAA);

	return 1;
}

=head2 name

 Title   : name
 Usage   : $name = $self->name();
 Function: the name of genetic code table in use
 Returns : a string for the name
 Args    : None

=cut

sub name
{
	$_[0]->get_tag('name');
}

=head2 id

 Title   : id
 Usage   : $id = $self->id();
 Function: the id of genetic code table in use
 Returns : a integer for the id
 Args    : None

=cut

sub id
{
	$_[0]->get_tag('id');
}

=head2 total_num_of_codons

 Title   : total_num_of_codons
 Usage   : $num = $self->total_num_of_codons;
 Function: get total number of codons of the genetic code table in use
 Returns : an integer
 Args    : None

=cut

sub total_num_of_codons
{
	$_[0]->{'_num_codons'};
}

sub _is_valid_gc_id
{
	my ($self, $id) = @_;
	
	return 1 if($validGCIds{$id});
	return 0;
}

# check whether this AA is a stop symbol
sub _is_stop_aa
{
	my ($self, $AA) = @_;

	return 1 if($AA eq $STOPAA);
	return 0;
}

=head2 is_valid_codon

 Title   : is_valid_codon
 Usage   : $test = $self->is_valid_codon('ACG');
 Function: test whether a given character string is a valid codon in
 current codon table
 Returns : 1 if true, otherwise 0
 Args    : a codon sequence

=cut
# check whether this is a valid codon
sub is_valid_codon
{
	my ($self,$codon,$allowAmb) = @_;

	$codon = _process_codon($codon);
	return 0 unless($codon =~ /^[ATCGU]{3}$/); # no ambiguous at present
	# also check whether it is in codon table
	my $codons = $self->{'_codon_to_aa'};
	return 0 unless(exists $codons->{$codon});
	return 1;
}

=head2 all_codons

 Title   : all_codons
 Usage   : @codons = $self->all_codons;
 Function: get all the codons in this genetic code table. Codons are
 ordered by the coded amino acids. Stop codons are also included.
 Returns : an array of codons, or its reference in scalar context
 Args    : None

=cut

sub all_codons
{
	my ($self) = @_;

	my $codonToAA = $self->{'_codon_to_aa'} or return;

	my %AAs;
	while(my ($k,$v) = each %$codonToAA)
	{
		push @{$AAs{$v}}, $k;
	}

	# now order the codons
	my @sortedAAs = sort keys(%AAs);
	my @codons;
	foreach my $AA (@sortedAAs)
	{
		push @codons, @{$AAs{$AA}};
	}

	return wantarray? @codons : \@codons;
}

=head2 all_sense_codons

 Title   : all_sense_codons
 Usage   : @codons = $self->all_sense_codons;
 Function: get all the sense codons in this genetic code table
 Returns : an array of codons, or its reference in scalar context
 Args    : None

=cut

sub all_sense_codons
{
	my ($self) = @_;

	my $codonToAA = $self->{'_codon_to_aa'};
	my $stopCodons = $self->{'_stop_codons'};
	my @senseCodons = grep {!exists($stopCodons->{$_})} keys %$codonToAA;

	return wantarray? @senseCodons : \@senseCodons;
}

=head2 all_amino_acids

 Title   : all_amino_acids
 Usage   : @AAs = $self->all_amino_acids
 Function: get all the amino acids in this genetic code table. Stop
 codons are excluded.
 Returns : an array of amino acids, or its reference if in scalar
 context
 Args    : None

=cut

sub all_amino_acids
{
	my $self = shift;
	my $codonToAA = $self->{'_codon_to_aa'} or return;

	my %AAs;
	while(my ($k,$v) = each %$codonToAA)
	{
		next if $self->_is_stop_aa($v);
		$AAs{$v}++;
	}

	my @tmp = keys %AAs;
	return wantarray? @tmp : \@tmp;
}

=head2 all_start_codons

 Title   : all_start_codons
 Usage   : @startCodons = $self->all_start_codons;
 Function: get all the start codons in the genetic code table in use
 Returns : an array of codons, or its reference if in scalar context
 Args    : None

=cut

sub all_start_codons
{
	my $self = shift;
	$self->warn("No marked start codons in this GC table") and return
	unless(exists $self->{'_start_codons'});
	my @codons = keys %{$self->{'_start_codons'}};
	wantarray? @codons : \@codons;
}

=head2 all_stop_codons

 Title   : all_stop_codons
 Usage   : @stopCodons = $self->all_stop_codons;
 Function: get all the stop codons in the genetic code table in use
 Returns : an array of codons, or its reference if in scalar context
 Args    : None

=cut

sub all_stop_codons
{
	my @codons = keys %{$_[0]->{'_stop_codons'}};
	wantarray? @codons : \@codons;
}

=head2 codons_of_AA

 Title   : codons_of_AA
 Usage   : @codons = $self->codons_of_AA('S');
 Function: get codons encoding the given amino acid
 Returns : an array of codons, or its reference if in scalar context
 Args    : a single amino acid; for stop codons, one can give '*' here

=cut

sub codons_of_AA
{
	my ($self, $AA) = @_;

	$AA =~ s/\s+//g; $AA = uc($AA);
	$self->throw("Can only process one amino acid each time")
	if(length($AA) > 1);

	my $codonToAA = $self->{'_codon_to_aa'};
	my @codons = grep { $codonToAA->{$_} eq $AA } keys %$codonToAA;

	return wantarray? @codons : \@codons;
}

=head2 codon_to_AA_map

 Title   : codon_to_AA_map
 Usage   : $hash = $self->codon_to_AA_map
 Function: get the mapping from codon to amino acid in a hash
 Returns : a hash reference in which codons are keys and AAs are
 values
 Args    : None

=cut

sub codon_to_AA_map
{
	$_[0]->{'_codon_to_aa'};
}

=head2 translate

 Title   : translate
 Usage   : $AA_string = $self->translate('ATGGCA');
 Function: get the translation of input nucleotides
 Returns : a string of amino acids, unknown amino acids are
 represented as 'X'.
 Args    : nucleotide sequence.
 Note : if the input sequence is not multiple of 3 long, the last
 remained 1 or 2 nucleotides would be simply ignored.

=cut

sub translate
{
	my ($self, $seq) = @_;

	$seq =~ s/\s+//g;
	$seq = uc($seq);

	my $seqLen = length($seq);
	my $accuLen = 0;
	my $AAs = '';
	my $codonToAA = $self->{'_codon_to_aa'};
	while($accuLen + 3 <= $seqLen)
	{
		my $codon = substr($seq, $accuLen, 3);
		$self->warn("'$codon' is not a valid codon") 
		unless($self->is_valid_codon($codon));
		$AAs .= exists $codonToAA->{$codon}? $codonToAA->{$codon} :
		'X'; # X for unknown codons
		$accuLen += 3;
	}

	return $AAs;
}

=head2 is_stop_codon

 Title   : is_stop_codon
 Usage   : $test = $self->is_stop_codon('UAG');
 Function: check whether this is a stop codon
 Returns : 1 if true, otherwise 0
 Args    : a codon sequence

=cut
# check whether 
sub is_stop_codon
{
	my ($self, $codon) = @_;
	my $stopCodons = $self->{'_stop_codons'};
	$codon = _process_codon($codon);
	return 1 if($stopCodons->{$codon});
	return 0;
}

# process codons before other actions
sub _process_codon
{
	my $codon = shift;
	$codon =~ s/\s+//g;
	$codon =~ tr/uU/TT/; # U to T
	return uc($codon);
}

=head2 codon_degeneracy

 Title   : codon_degeneracy
 Usage   : $hash = $self->codon_degeneracy;
 Function: group AAs and codons into codon degeneracy groups
 Returns : reference to a hash in which 1st level key is degeneracy
 (i.e., 1,2,6,etc), 2nd level key is amino acids for that degeneracy
 group, and 3rd level is reference of arrays containing coding codons
 for each amino acid. For example:

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

# group AAs and codons into redundancy groups
sub codon_degeneracy
{
	my $self = shift;

	return $self->{'_codon_deg'} if(exists $self->{'_codon_deg'});

	# otherwise construct it if its the first time
	my $codonToAA = $self->{'_codon_to_aa'};
	my %aaToCodon;
	while(my ($codon, $AA) = each %$codonToAA)
	{
		# ignore stop codons
		next if($self->is_stop_codon($codon)); 
		push @{$aaToCodon{$AA}}, $codon;
	}

	my %redundancy;
	while(my ($AA, $codons) = each %aaToCodon)
	{
		my $red = $#$codons + 1;
		$redundancy{$red}->{$AA} = [sort @$codons];
	}

	$self->{'_codon_deg'} = \%redundancy; # store it first
	return \%redundancy;
}


=head1 AUTHOR

Zhenguo Zhang, C<< <zhangz.sci at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-cua at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-CUA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::CUA::CodonTable


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

1; # End of Bio::CUA::CodonTable

__END__
-- data section
>>GC
-- downloaded from ftp://ftp.ncbi.nih.gov/entrez/misc/data/gc.prt
--**************************************************************************
--  This is the NCBI genetic code table
--  Initial base data set from Andrzej Elzanowski while at PIR International
--  Addition of Eubacterial and Alternative Yeast by J.Ostell at NCBI
--  Base 1-3 of each codon have been added as comments to facilitate
--    readability at the suggestion of Peter Rice, EMBL
--  Later additions by Taxonomy Group staff at NCBI
--
--  Version 4.0
--     Updated version to reflect numerous undocumented changes:
--     Corrected start codons for genetic code 25
--     Name of new genetic code is Candidate Division SR1 and Gracilibacteria
--     Added candidate division SR1 nuclear genetic code 25
--     Added GTG as start codon for genetic code 24
--     Corrected Pterobranchia Mitochondrial genetic code (24)
--     Added genetic code 24, Pterobranchia Mitochondrial
--     Genetic code 11 is now Bacterial, Archaeal and Plant Plastid
--     Fixed capitalization of mitochondrial in codes 22 and 23
--     Added GTG, ATA, and TTG as alternative start codons to code 13
--
--  Version 3.9
--     Code 14 differs from code 9 only by translating UAA to Tyr rather than
--     STOP.  A recent study (Telford et al, 2000) has found no evidence that
--     the codon UAA codes for Tyr in the flatworms, but other opinions exist.
--     There are very few GenBank records that are translated with code 14,
--     but a test translation shows that retranslating these records with code
--     9 can cause premature terminations.  Therefore, GenBank will maintain
--     code 14 until further information becomes available.
--
--  Version 3.8
--     Added GTG start to Echinoderm mitochondrial code, code 9
--
--  Version 3.7
--     Added code 23 Thraustochytrium mitochondrial code
--        formerly OGMP code 93
--        submitted by Gertraude Berger, Ph.D.
--
--  Version 3.6
--     Added code 22 TAG-Leu, TCA-stop
--        found in mitochondrial DNA of Scenedesmus obliquus
--        submitted by Gertraude Berger, Ph.D.
--        Organelle Genome Megasequencing Program, Univ Montreal
--
--  Version 3.5
--     Added code 21, Trematode Mitochondrial
--       (as deduced from: Garey & Wolstenholme,1989; Ohama et al, 1990)
--     Added code 16, Chlorophycean Mitochondrial
--       (TAG can translated to Leucine instaed to STOP in chlorophyceans
--        and fungi)
--
--  Version 3.4
--     Added CTG,TTG as allowed alternate start codons in Standard code.
--        Prats et al. 1989, Hann et al. 1992
--
--  Version 3.3 - 10/13/95
--     Added alternate intiation codon ATC to code 5
--        based on complete mitochondrial genome of honeybee
--        Crozier and Crozier (1993)
--
--  Version 3.2 - 6/24/95
--  Code       Comments
--   10        Alternative Ciliate Macronuclear renamed to Euplotid Macro...
--   15        Bleharisma Macro.. code added
--    5        Invertebrate Mito.. GTG allowed as alternate initiator
--   11        Eubacterial renamed to Bacterial as most alternate starts
--               have been found in Achea
--
--
--  Version 3.1 - 1995
--  Updated as per Andrzej Elzanowski at NCBI
--     Complete documentation in NCBI toolkit documentation
--  Note: 2 genetic codes have been deleted
--
--   Old id   Use id     - Notes
--
--   id 7      id 4      - Kinetoplast code now merged in code id 4
--   id 8      id 1      - all plant chloroplast differences due to RNA edit
--
--*************************************************************************

Genetic-code-table ::= {
 {
  name "Standard" ,
  name "SGC0" ,
  id 1 ,
  ncbieaa  "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "---M---------------M---------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Vertebrate Mitochondrial" ,
  name "SGC1" ,
  id 2 ,
  ncbieaa  "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSS**VVVVAAAADDEEGGGG",
  sncbieaa "--------------------------------MMMM---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Yeast Mitochondrial" ,
  name "SGC2" ,
  id 3 ,
  ncbieaa  "FFLLSSSSYY**CCWWTTTTPPPPHHQQRRRRIIMMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "----------------------------------MM----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
    name "Mold Mitochondrial; Protozoan Mitochondrial; Coelenterate
 Mitochondrial; Mycoplasma; Spiroplasma" ,
  name "SGC3" ,
  id 4 ,
  ncbieaa  "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "--MM---------------M------------MMMM---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Invertebrate Mitochondrial" ,
  name "SGC4" ,
  id 5 ,
  ncbieaa  "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSSSVVVVAAAADDEEGGGG",
  sncbieaa "---M----------------------------MMMM---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Ciliate Nuclear; Dasycladacean Nuclear; Hexamita Nuclear" ,
  name "SGC5" ,
  id 6 ,
  ncbieaa  "FFLLSSSSYYQQCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "-----------------------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Echinoderm Mitochondrial; Flatworm Mitochondrial" ,
  name "SGC8" ,
  id 9 ,
  ncbieaa  "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG",
  sncbieaa "-----------------------------------M---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Euplotid Nuclear" ,
  name "SGC9" ,
  id 10 ,
  ncbieaa  "FFLLSSSSYY**CCCWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "-----------------------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Bacterial, Archaeal and Plant Plastid" ,
  id 11 ,
  ncbieaa  "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "---M---------------M------------MMMM---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Alternative Yeast Nuclear" ,
  id 12 ,
  ncbieaa  "FFLLSSSSYY**CC*WLLLSPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "-------------------M---------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Ascidian Mitochondrial" ,
  id 13 ,
  ncbieaa  "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSGGVVVVAAAADDEEGGGG",
  sncbieaa "---M------------------------------MM---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 },
 {
  name "Alternative Flatworm Mitochondrial" ,
  id 14 ,
  ncbieaa  "FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG",
  sncbieaa "-----------------------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Blepharisma Macronuclear" ,
  id 15 ,
  ncbieaa  "FFLLSSSSYY*QCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "-----------------------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Chlorophycean Mitochondrial" ,
  id 16 ,
  ncbieaa  "FFLLSSSSYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "-----------------------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Trematode Mitochondrial" ,
  id 21 ,
  ncbieaa  "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNNKSSSSVVVVAAAADDEEGGGG",
  sncbieaa "-----------------------------------M---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Scenedesmus obliquus Mitochondrial" ,
  id 22 ,
  ncbieaa  "FFLLSS*SYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "-----------------------------------M----------------------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Thraustochytrium Mitochondrial" ,
  id 23 ,
  ncbieaa  "FF*LSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "--------------------------------M--M---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Pterobranchia Mitochondrial" ,
  id 24 ,
  ncbieaa  "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSSKVVVVAAAADDEEGGGG",
  sncbieaa "---M---------------M---------------M---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 } ,
 {
  name "Candidate Division SR1 and Gracilibacteria" ,
  id 25 ,
  ncbieaa  "FFLLSSSSYY**CCGWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG",
  sncbieaa "---M-------------------------------M---------------M------------"
  -- Base1  TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  -- Base2  TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  -- Base3  TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
 }
}
<<GC # end of genetic code section

<<END_DATA

