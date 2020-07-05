#
# GeneDesign engine
#

=head1 NAME

Bio::GeneDesign

=head1 VERSION

Version 5.56

=head1 DESCRIPTION

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>

=cut

package Bio::GeneDesign;
use base qw(Bio::Root::Root);

use Bio::GeneDesign::ConfigData;
use Bio::GeneDesign::Basic qw(:GD);
use Bio::GeneDesign::IO qw(:GD);
use Bio::GeneDesign::CodonJuggle qw(:GD);
use Bio::GeneDesign::Codons qw(:GD);
use Bio::GeneDesign::Oligo qw(:GD);
use Bio::GeneDesign::Random qw(:GD);
use Bio::GeneDesign::RestrictionEnzymes qw(:GD);
use Bio::GeneDesign::ReverseTranslate qw(:GD);
use Bio::GeneDesign::PrefixTree;
use Bio::SeqFeature::Generic;
use File::Basename;
use Bio::Seq;
use Carp;

use strict;
use warnings;

my $VERSION = 5.56;

=head1 CONSTRUCTORS

=head2 new

Returns an initialized Bio::GeneDesign object.

This function reads the ConfigData written at installation, imports the
relevant sublibraries, and sets the relevant paths.

    my $GD = Bio::GeneDesign->new();

=cut

sub new
{
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);
  bless $self, $class;

  $self->{script_path} = Bio::GeneDesign::ConfigData->config('script_path');
  $self->{conf} = Bio::GeneDesign::ConfigData->config('conf_path');
  $self->{conf} .= q{/} unless substr($self->{conf}, -1, 1) eq q{/};

  $self->{tmp_path} = Bio::GeneDesign::ConfigData->config('tmp_path');
  $self->{tmp_path} .= q{/} unless substr($self->{tmp_path}, -1, 1) eq q{/};

  $self->{graph} = Bio::GeneDesign::ConfigData->config('graphing_support');
  if ($self->{graph} > 0)
  {
    require Bio::GeneDesign::Graph;
    import Bio::GeneDesign::Graph qw(:GD);
  }

  $self->{EMBOSS} = Bio::GeneDesign::ConfigData->config('EMBOSS_support');
  if ($self->{EMBOSS})
  {
    require Bio::GeneDesign::Palindrome;
    import Bio::GeneDesign::Palindrome qw(:GD);
  }

  $self->{BLAST} = Bio::GeneDesign::ConfigData->config('BLAST_support');
  if ($self->BLAST)
  {
    #$ENV{BLASTPLUSDIR} = Bio::GeneDesign::ConfigData->config('blast_path');
    require Bio::GeneDesign::Blast;
    import Bio::GeneDesign::Blast qw(:GD);
  }

  $self->{vmatch} = Bio::GeneDesign::ConfigData->config('vmatch_support');
  if ($self->{vmatch})
  {
    require Bio::GeneDesign::Vmatch;
    import Bio::GeneDesign::Vmatch qw(:GD);
  }

  $self->{codon_path} = $self->{conf} . 'codon_tables/';
  $self->{organism} = undef;
  $self->{codontable} = undef;
  $self->{enzyme_set} = undef;
  $self->{version} = $VERSION;
  $self->{amb_trans_memo} = {};

  return $self;
}

=head1 ACCESSORS

=cut

=head2 codon_path

returns the directory containing codon tables

=cut

sub codon_path
{
  my ($self) = @_;
  return $self->{codon_path};
}

=head2 EMBOSS

returns a value if EMBOSS_support was vetted and approved during installation.

=cut

sub EMBOSS
{
  my ($self) = @_;
  return $self->{'EMBOSS'};
}

=head2 BLAST

returns a value if BLAST_support was vetted and approved during installation.

=cut

sub BLAST
{
  my ($self) = @_;
  return $self->{'BLAST'};
}

=head2 graph

returns a value if graphing_support was vetted and approved during installation.

=cut

sub graph
{
  my ($self) = @_;
  return $self->{'graph'};
}

=head2 vmatch

returns a value if vmatch_support was vetted and approved during installation.

=cut

sub vmatch
{
  my ($self) = @_;
  return $self->{'vmatch'};
}

=head2 enzyme_set

Returns a hash reference where the keys are enzyme names and the values are
L<RestrictionEnzyme|Bio::GeneDesign::RestrictionEnzyme> objects, if the enzyme
set has been defined.

To set this value, use L<set_restriction_enzymes|/set_restriction_enzymes>.

=cut

sub enzyme_set
{
  my ($self) = @_;
  return $self->{'enzyme_set'};
}

=head2 enzyme_set_name

Returns the name of the enzyme set in use, if there is one.

To set this value, use L<set_restriction_enzymes|/set_restriction_enzymes>.

=cut

sub enzyme_set_name
{
  my ($self) = @_;
  return $self->{'enzyme_set_name'};
}

=head2 all_enzymes

Returns a hash reference where the keys are enzyme names and the values are
L<RestrictionEnzyme|Bio::GeneDesign::RestrictionEnzyme> objects

To set this value, use L<set_restriction_enzymes|/set_restriction_enzymes>.

=cut

sub all_enzymes
{
  my ($self) = @_;
  return $self->{'all_enzymes'};
}

=head2 organism

Returns the name of the organism in use, if there is one.

To set this value, use L<set_organism|/set_organism>.

=cut

sub organism
{
  my ($self) = @_;
  return $self->{'organism'};
}

=head2 codontable

Returns the codon table in use, if there is one.

The codon table is a hash reference where the keys are upper case nucleotides
and the values are upper case single letter amino acids.

    my $codon_t = $GD->codontable();
    $codon_t->{"ATG"} eq "M" || die;

To set this value, use L<set_codontable|/set_codontable>.

=cut

sub codontable
{
  my ($self) = @_;
  return $self->{'codontable'};
}

=head2 reversecodontable

Returns the reverse codon table in use, if there is one.

The reverse codon table is a hash reference where the keys are upper case single
letter amino acids and the values are upper case nucleotides.

    my $revcodon_t = $GD->reversecodontable();
    $revcodon_t->{"M"} eq "ATG" || die;

This value is set automatically when L<set_codontable|/set_codontable> is run.

=cut

sub reversecodontable
{
  my ($self) = @_;
  return $self->{'reversecodontable'};
}

=head2 rscutable

Returns the RSCU table in use, if there is one.

The RSCU codon table is a hash reference where the keys are upper case
nucleotides and the values are floats.

    my $rscu_t = $GD->rscutable();
    $rscu_t->{"ATG"} eq 1.00 || die;

To set this value, use L<set_rscu_table|/set_rscutable>.

=cut

sub rscutable
{
  my ($self) = @_;
  return $self->{'rscutable'};
}


=head1 FUNCTIONS

=cut

=head2 melt

    my $Tm = $GD->melt(-sequence => $myseq);

The -sequence argument is required.

Returns the melting temperature of a DNA sequence.

You can set the salt and DNA concentrations with the -salt and -concentration
arguments; they are 50mm (.05) and 100 pm (.0000001) respectively.

You can pass either a string variable, a Bio::Seq object, or a Bio::SeqFeatureI
object to be analyzed with the -sequence flag.

There are four different formulae to choose from. If you wish to use the nearest
neighbor method, use the -nearest_neighbor flag. Otherwise the appropriate
formula will be determined by the length of your -sequence argument.

For sequences under 14 base pairs:
  Tm = (4 * #GC) + (2 * #AT).

For sequences between 14 and 50 base pairs:
  Tm = 100.5 + (41 * #GC / length) - (820 / length) + 16.6 * log10(salt)

For sequences over 50 base pairs:
  Tm = 81.5 + (41 * #GC / length) - (500 / length) + 16.6 * log10(salt) - .62;

=cut

sub melt
{
  my ($self, @args) = @_;

  my ($seq, $salt, $conc, $nnflag)
    = $self->_rearrange([qw(
        sequence
        salt
        concentration
        nearest_neighbor)], @args);

  $self->throw("No sequence provided for the melt function")
    unless ($seq);

  $nnflag = $nnflag ? 1 : 0;
  $salt = $salt || .05;
  $conc = $conc || .0000001;
  my $str = $self->_stripdown($seq, q{}, 1);

  if ($nnflag)
  {
    return _ntherm($str, $salt, $conc);
  }
  return _melt($str, $salt, $conc);
}

=head2 complement

    $my_seq = "AATTCG";

    my $complemented_seq = $GD->complement($my_seq);
    $complemented_seq eq "TTAAGC" || die;

    my $reverse_complemented_seq = $GD->complement($my_seq, 1);
    $reverse_complemented_seq eq "CGAATT" || die;

    #clean
    my $complemented_seq = $GD->complement(-sequence => $my_seq);
    $complemented_seq eq "TTAAGC" || die;

    my $reverse_complemented_seq = $GD->complement(-sequence => $my_seq,
                                                   -reverse => 1);
    $reverse_complemented_seq eq "CGAATT" || die;


The -sequence argument is required.

Complements or reverse complements a DNA sequence.

You can pass either a string variable, a Bio::Seq object, or a Bio::SeqFeatureI
object to be processed.

If you also pass along a true statement, the sequence will be reversed and
complemented.

=cut

sub complement
{
  my ($self, @args) = @_;

  my ($seq, $swit)
    = $self->_rearrange([qw(
        sequence
        reverse)], @args);

  $self->throw("No sequence provided for the complement function")
    unless $seq;

  $swit = $swit || 0;

  my $str = $self->_stripdown($seq, q{}, 1);

  return _complement($str, $swit);
}

=head2 rcomplement

Sugar time!

    $my_seq = "AATTCG";

    my $reverse_complemented_seq = $GD->rcomplement($my_seq);
    $reverse_complemented_seq eq "CGAATT" || die;

    #clean

    my $reverse_complemented_seq = $GD->complement(-sequence => $my_seq,
                                                   -reverse => 1);
    $reverse_complemented_seq eq "CGAATT" || die;


The -sequence argument is required.

Reverse complements a DNA sequence.

You can pass either a string variable, a Bio::Seq object, or a Bio::SeqFeatureI
object to be processed.

=cut

sub rcomplement
{
  my ($self, @args) = @_;

  my ($seq) = $self->_rearrange([qw(sequence)], @args);

  $self->throw('No sequence provided for the rcomplement function')
    unless $seq;

  my $str = $self->_stripdown($seq, q{}, 1);

  return _complement($str, 1);
}

=head2 transcribe

    $my_seq = "AATTCG";

    my $RNA_seq = $GD->transcribe($my_seq);
    $complemented_seq eq "AAUUCG" || die;

The -sequence argument is required.

Transcribes an RNA sequence from a DNA sequence.

You can pass either a string variable, a Bio::Seq object, or a Bio::SeqFeatureI
object to be processed.

=cut

sub transcribe
{
  my ($self, @args) = @_;

  my ($seq) = $self->_rearrange([qw(sequence)], @args);

  $self->throw("No sequence provided for the transcribe function")
    unless $seq;

  my $str = $self->_stripdown($seq, q{}, 1);

  return _toRNA($str);
}

=head2 count

    $my_seq = "AATTCG";
    my $count = $GD->count($my_seq);
    $count->{C} == 1 || die;
    $count->{G} == 1 || die;
    $count->{A} == 2 || die;
    $count->{GCp} == 33.3 || die;
    $count->{ATp} == 66.7 || die;

    #clean
    my $count = $GD->count(-sequence => $my_seq);

You must pass either a string variable, a Bio::Seq object, or a Bio::SeqFeatureI
object.

the count function counts the bases in a DNA sequence and returns a hash
reference where each base (including the ambiguous bases) are keys and the
values are the number of times they appear in the sequence. There are also the
special values GCp and ATp for GC and AT percentage.

=cut

sub count
{
  my ($self, @args) = @_;

  my ($seq) = $self->_rearrange([qw(sequence)], @args);

  $self->throw("No sequence provided for the count function")
    unless ($seq);


  my $str = $self->_stripdown($seq, q{}, 1);

  return _count($str);
}


=head2 GC_windows

takes a nucleotide sequence, a window size, and minimum and maximum values.
returns lists of real coordinates of subsequences that violate mimimum or
maximum GC percentages.

Values are returned inside an array reference such that the first value is an
array ref of minimum violators (as array refs of left/right coordinates), and
the second value is an array ref of maximum violators.

$return_value = [
  [[left, right], [left, right]], #minimum violators
  [[left, right], [left, right]]  #maximum violators
];

=cut

sub GC_windows
{
  my ($self, @args) = @_;

  my ($seq, $win, $min, $max) = $self->_rearrange([qw(
    sequence window minimum maximum)], @args);

  $self->throw("No sequence provided for the GC_windows function")
    unless ($seq);

  my $str = $self->_stripdown($seq, q{}, 1);

  return _gcwindows($str, $win, $min, $max);
}

=head2 regex_nt

    my $my_seq = "ABC";
    my $regex = $GD->regex_nt(-sequence => $my_seq);
    # $regex is qr/A[CGT]C/;

    my $regarr = $GD->regex_nt(-sequence => $my_seq --reverse_complement => 1);
    # $regarr is [qr/A[CGT]C/, qr/G[ACG]T/]


You must pass either a string variable, a Bio::Seq object, or a Bio::SeqFeatureI
object to be processed with the -sequence flag.

regex_nt creates a compiled regular expression or a set of them that can be used
to query large nucleotide sequences for possibly ambiguous subsequences.


If you want to get regular expressions for both the forward and reverse senses
of the DNA, use the -reverse_complement flag and expect a reference to an array
of compiled regexes.

=cut

sub regex_nt
{
  my ($self, @args) = @_;

  my ($seq, $arrswit)
    = $self->_rearrange([qw(
        sequence
        reverse_complement)], @args
  );

  $self->throw("no sequence provided the regex_nt function")
    unless ($seq);

  my $str = $self->_stripdown($seq, q{}, 1);

  if ($arrswit)
  {
    return _regarr($str);
  }
  else
  {
    return _regres($str, 1);
  }
}

=head2 regex_aa

    my $my_pep = "AEQ*";
    my $regex = $GD->regex_aa(-sequence => $my_pep);
    $regex == qr/AEQ[\*]/ || die;

Creates a compiled regular expression or a set of them that can be used to query
large amino acid sequences for smaller subsequences.

You can pass either a string variable, a Bio::Seq object, or a Bio::SeqFeatureI
object to be processed with the -sequence flag.

=cut

sub regex_aa
{
  my ($self, $seq) = @_;

  $self->throw("no sequence provided for the regex_aa function")
    unless ($seq);

  my $str = $self->_stripdown($seq, q{}, 1);

  return _regres($str, 2);
}

=head2 sequence_is_ambiguous

    my $my_seq = "ABC";
    my $flag = $GD->sequence_is_ambiguous($my_seq);
    $flag == 1 || die;

    $my_seq = "ATC";
    $flag = $GD->sequence_is_ambiguous($my_seq);
    $flag == 0 || die;

Checks to see if a DNA sequence contains ambiguous bases (RYMKWSBDHVN) and
returns true if it does.

You can pass either a string variable, a Bio::Seq object, or a Bio::SeqFeatureI
object to be processed.

=cut

sub sequence_is_ambiguous
{
  my ($self, $seq) = @_;

  $self->throw("no sequence provided for the sequence_is_ambiguous function")
    unless ($seq);

  my $str = $self->_stripdown($seq, q{}, 1);

  return _is_ambiguous($str);
}

=head2 ambiguous_translation

    my $my_seq = "ABC";
    my @peps = $GD->ambiguous_translation(-sequence => $my_seq, -frame => 1);
    # @peps is qw(I T C)

You must pass a string variable, a Bio::Seq object, or a Bio::SeqFeatureI object
to be processed.

Translates a nucleotide sequence that may have ambiguous bases and returns an
array of possible peptides.

The frame argument may be 1, 2, 3, -1, -2, or -3.
It may also be t (three, 1, 2, 3), or s (six, 1, 2, 3, -1, -2, -3).
It defaults to 1.

=cut

sub ambiguous_translation
{
  my ($self, @args) = @_;

  my ($seq, $frame)
    = $self->_rearrange([qw(sequence frame)], @args);

  $self->throw("no sequence provided for the ambiguous_translation function")
    unless ($seq);

  $frame = $frame || 1;

  my %ambtransswits = map {$_ => 1} qw(1 2 3 -1 -2 -3 s t);

  $self->throw("Bad frame argument to ambiguous_translation")
    unless (exists $ambtransswits{$frame});

  my $str = $self->_stripdown($seq, q{}, 1);

  return _amb_translation($str,
                          $self->{codontable},
                          $frame,
                          $self->{amb_trans_memo});
}

=head2 ambiguous_transcription

    my $my_seq = "ABC";
    my $seqs = $GD->ambiguous_transcription($my_seq);
    # $seqs is [qw(ACC AGC ATC)]

Deambiguates a nucleotide sequence that may have ambiguous bases and returns a
reference to a sorted array of possible unambiguous sequences.

You can pass either a string variable, a Bio::Seq object, or a Bio::SeqFeatureI
object to be processed.

=cut

sub ambiguous_transcription
{
  my ($self, $seq) = @_;

  $self->throw("no sequence provided for the ambiguous_transcription function")
    unless ($seq);

  my $str = $self->_stripdown($seq, q{}, 1);

  return _amb_transcription($str);
}

=head2 positions

    my $seq = "TGCTGACTGCAGTCAGTACACTACGTACGTGCATGAC";
    my $seek = "CWC";

    my $positions = $GD->positions(-sequence => $seq,
                                   -query => $seek);
    # $positions is {18 => "CAC"}

    $positions = $GD->positions(-sequence => $seq,
                                -query => $seek,
                                -reverse_complement => 1);
    # $positions is {18 => "CAC", 28 => "GTG"}

Finds and returns all the positions and sequences of a potentially ambiguous
subsequence in a larger sequence. The reverse_complement flag is off by default.

You can pass either string variables, Bio::Seq objects, or Bio::SeqFeatureI
objects as the sequence and query arguments; additionally you may pass a
L<RestrictionEnzyme|Bio::GeneDesign::RestrictionEnzyme> object as the query
argument.

=cut

sub positions
{
  my ($self, @args) = @_;

  my ($seq, $seek, $revcom)
    = $self->_rearrange([qw(
        sequence
        query
        reverse_complement)], @args);

  $self->throw("no sequence provided for the positions function")
    unless ($seq);

  $self->throw("no query provided for the positions function")
    unless ($seek);


  my $base = $self->_stripdown($seq, q{}, 1);

  my $regarr = [];
  my $query = $seek;
  my $qref = ref($seek);
  if ($qref)
  {
    $self->throw("object $qref is not a Bio::Seq or Bio::SeqFeature, or " .
      "Bio::GeneDesign::RestrictionEnzyme object")
      unless ($seek->isa("Bio::Seq")
           || $seek->isa("Bio::SeqFeatureI")
           || $seek->isa("Bio::GeneDesign::RestrictionEnzyme"));
    if ($seek->isa("Bio::GeneDesign::RestrictionEnzyme"))
    {
      $regarr = $seek->regex;
    }
    else
    {
      $query = ref($seek->seq)  ? $seek->seq->seq  : $seek->seq;
      $regarr = $revcom ? _regarr($query, 1) : [_regres($query, 1)];
    }
  }
  else
  {
    $regarr = $revcom ? _regarr($query, 1) : [_regres($query, 1)];
  }

  return _positions($base, $regarr);
}

=head2 parse_organisms

Returns two hash references. The first contains the names of all rscu tables.
The second contains the name of all codon tables.

=cut

sub parse_organisms
{
  my ($self) = @_;
  my ($rscu, $cods) = _parse_organisms($self->{codon_path});
  return ($rscu, $cods);
}

=head2 set_codontable

    # load a codon table from the GeneDesign configuration directory
    $GD->set_codontable(-organism_name => "yeast");

    # load a codon table from an arbitrary path and catch it in a variable
    my $codon_t = $GD->set_codontable(-organism_name => "custom",
                                      -table_path => "/path/to/table.ct");

The -organism_name argument is required.

This function loads, sets, and returns a codon definition table. After it is run
the accessor L<codontable|/codontable> will return the hash reference that
represents the codon table.

If no path is provided, the configuration directory /codon_tables is checked for
tables that match the provided organism name. Any codon table that is using a
non standard definition for a codon will cause a warning to be issued.

The table format for codon tables is

    # Standard genetic code
    {TTT} = F
    {TTC} = F
    {TTA} = L
    ...

See L<NCBI's table|http://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi#SG1>

=cut

sub set_codontable
{
  my ($self, @args) = @_;
  my ($orgname, $table_path)
    = $self->_rearrange([qw(
        organism_name
        table_path)], @args);

  $self->throw("No organsim name provided") unless ($orgname);
  $self->{organism} = $orgname;

  $self->throw("$table_path does not exist")
    if ($table_path && ! -e $table_path);

  if (! $table_path )
  {
    $table_path = $self->{codon_path} . $orgname . ".ct";
    if (-e $table_path && $orgname ne 'Standard')
    {
      warn "Using nonstandard codon definitions for $orgname\n";
    }
    else
    {
      $table_path = $self->{codon_path} . "Standard.ct";
    }
  }

  $self->{codontable} = _parse_codon_file($table_path);
  $self->{reversecodontable} = _reverse_codon_table($self->{codontable});
  return $self->{codontable};
}

=head2 set_rscutable

    # load a RSCU table from the GeneDesign configuration directory
    $GD->set_rscutable(-organism_name => "yeast");

    # load an RSCU table from an arbitrary path and catch it in a variable
    my $rscu_t = $GD->set_rscutable(-organism_name => "custom",
                                    -table_path => "/path/to/table.rscu");

The -organism_name argument is required.

This function loads, sets, and returns an RSCU table. After it is run
the accessor L<rscutable|/rscutable> will return the hash reference that
represents the RSCU table.

If no path is provided, the configuration directory /codon_tables is checked for
tables that match the provided organism name. If there is no table in that
directory, a warning will appear and the flat RSCU table will be used.

Any RSCU table that is missing a definition for a codon will cause a warning to
be issued. The table format for RSCU tables is

    # Saccharomyces cerevisiae (Highly expressed genes)
    # Nucleic Acids Res 16, 8207-8211 (1988)
    {TTT} = 0.19
    {TTC} = 1.81
    {TTA} = 0.49
    ...

See L<Sharp et al. 1986|http://www.ncbi.nlm.nih.gov/pubmed/3526280>.

=cut

sub set_rscutable
{
  my ($self, @args) = @_;
  my ($orgname, $rscu_path)
    = $self->_rearrange([qw(
        organism_name
        rscu_path)], @args);

  $self->throw("No organsim name provided") unless ($orgname);
  $self->{organism} = $orgname;

  $self->throw("$rscu_path does not exist")
    if ($rscu_path && ! -e $rscu_path);

  if (! $rscu_path)
  {
    $rscu_path = $self->{codon_path} . $orgname . ".rscu";
    if (! -e $rscu_path)
    {
      warn "No RSCU table for $orgname found. Using Unbiased values\n";
      $rscu_path = $self->{codon_path} . "Unbiased.rscu";
    }
  }

  $self->{rscutable} = _parse_codon_file($rscu_path);
  return $self->{rscutable};
}

=head2 set_organism

    # load both codon tables and RSCU tables simultaneously
    $GD->set_organism(-organism_name => "yeast");

    # with arguments
    $GD->set_organism(-organism_name => "custom",
                      -table_path => "/path/to/table.ct",
                      -rscu_path => "/path/to/table.rscu");


The -organism_name argument is required.

This function is just a shortcut; it runs L<set_codontable/set_codontable> and
L<set_rscutable/set_rscutable>. See those functions for details.

=cut

sub set_organism
{
  my ($self, @args) = @_;

  my ($orgname, $table_path, $rscu_path)
    = $self->_rearrange([qw(
        organism_name
        table_path
        rscu_path)], @args);

  $self->throw("No organsim name provided") unless ($orgname);
  $self->{organism} = $orgname;

  $self->set_codontable(-organism_name => $orgname, -table_path => $table_path);
  $self->set_rscutable(-organism_name => $orgname, -rscu_path=> $rscu_path);

  return;
}

=head2 codon_count

    # count the codons in a list of sequences
    my $tally = $GD->codon_count(-input => \@sequences);

    # add a gene to an existing codon count
    $tally = $GD->codon_count(-input => $sequence,
                              -count => $tally);

    # add a list of Bio::Seq objects to an existing codon count
    $tally = $GD->codon_count(-input => \@seqobjects,
                              -count => $tally);

The -input argument is required and will take a string variable, a Bio::Seq
object, a Bio::SeqFeatureI object, or a reference to an array full of any
combination of those things.

The codon_count function takes a set of sequences and counts how often each
codon appears in them. It returns a hash reference where the keys are upper case
nucleotide codons and the values are integers. If you pass a hash reference
containing codon counts with the -count argument, new counts will be added to
the old values.

This function will warn you if non nucleotide codons are found.

TODO: what about ambiguous codons?

=cut

sub codon_count
{
  my ($self, @args) = @_;

  my ($input, $count) = $self->_rearrange([qw(input count)], @args);

  $self->throw("no codon table has been defined")
    unless $self->{codontable};

  $self->throw("no sequences were provided to count")
    unless $input;

  my $list = $self->_stripdown($input, 'ARRAY', 0);

  my $cod_count = _codon_count($list,
                              $self->{codontable},
                              $count);

  warn("There are bad codons in codon count\n") if (exists $cod_count->{XXX});

  return $cod_count;
}

=head2 generate_RSCU_table

    my $rscu_t = $GD->generate_RSCU_table(-sequences => \@list_of_sequences);

The -sequences argument is required and will take a string variable, a Bio::Seq
object, a Bio::SeqFeatureI object, or a reference to an array full of any
combination of those things.

The generate_RSCU_table function takes a set of sequences, counts how often each
codon appears, and returns an RSCU table as a hash reference where the keys are
upper case nucleotide codons and the values are floats.

See L<Sharp et al. 1986|http://www.ncbi.nlm.nih.gov/pubmed/3526280>.

=cut

sub generate_RSCU_table
{
  my ($self, @args) = @_;

  my ($seqobjs) = $self->_rearrange([qw(sequences)], @args);

  $self->throw("no codon table has been defined")
    unless $self->{codontable};

  $self->throw("Sequence set must be provided")
    unless ($seqobjs);

  return _generate_RSCU_table(
    $self->codon_count(-input => $seqobjs),
    $self->{codontable},
    $self->{reversecodontable}
  );
}

=head2 generate_codon_report

  my $report = $GD->generate_codon_report(-sequences => \@list_of_sequences);

The report will have the format

  TTT (F) 12800 0.74
  TTC (F) 21837 1.26
  TTA (L)  4859 0.31
  TTG (L) 18806 1.22

where the first column in each group is the codon, the second column is the one
letter amino acid abbreviation in parentheses, the third column is the number of
times that codon has been seen, and the fourth column is the RSCU value for that
codon.

This report comes in a 4x4 layout, as would a standard genetic code table in a
textbook.

NO TEST

=cut

sub generate_codon_report
{
  my ($self, @args) = @_;

  my ($seqobjs) = $self->_rearrange([qw(sequences)], @args);

  $self->throw("no codon table has been defined")
    unless $self->{codontable};

  $self->throw("Sequence set must be provided")
    unless ($seqobjs);

  my $count_t = $self->codon_count(-input => $seqobjs);

  my $rscu_t = _generate_RSCU_table(
    $count_t,
    $self->{codontable},
    $self->{reversecodontable}
  );

  my $report = _generate_codon_report(
    $count_t,
    $self->{codontable},
    $rscu_t
  );

  return $report;
}

=head2 generate_RSCU_file

  my $contents = $GD->generate_RSCU_file(
    -sequences => \@seqs,
    -comments => ["Got these codons from mice"]
  );
  open (my $OUT, '>', '/path/to/cods') || die "can't write to /path/to/cods";
  print $OUT $contents;
  close $OUT;

This function generates a string that can be written to file to serve as a
GeneDesign RSCU table. Provide a set of sequences and an optional array
reference of comments to prepend to the file.

The file will have the format
  # Comment 1
  # ...
  # Comment n
  {TTT} = 0.19
  {TTC} = 1.81
  ...

NO TEST

=cut

sub generate_RSCU_file
{
  my ($self, @args) = @_;

  my ($seqobjs, $comments) = $self->_rearrange([qw(sequences comments)], @args);

  $self->throw('No codon table has been defined')
    unless $self->{codontable};

  $self->throw('Sequence set must be provided')
    unless ($seqobjs);

  $self->throw('Comment argument must be array reference')
    unless ref($comments) eq 'ARRAY';

  my $count_t = $self->codon_count(-input => $seqobjs);

  my $rscu_t = _generate_RSCU_table(
    $count_t,
    $self->{codontable},
    $self->{reversecodontable}
  );

  my $report = _generate_codon_file(
    $rscu_t,
    $self->{reversecodontable},
    $comments
  );

  return $report;
}

=head2 list_enzyme_sets

  my @available_enzlists = $GD->list_enzyme_sets();
  # @available_enzlists == ('standard_and_IIB', 'blunts', 'IIB', 'nonpal', ...)

Returns an array containing the names of every restriction enzyme recognition
list GeneDesign knows about.

=cut

sub list_enzyme_sets
{
  my ($self) = @_;
  my $epath = $self->{conf} . 'enzymes/';
  my @sets = ();
  opendir (my $ENZDIR, $epath) || $self->throw("can't opendir $epath");
  foreach my $list (readdir($ENZDIR))
  {
    my $name = basename($list);
    $name =~ s{\.[^.]+$}{}x;
    next if ($name eq q{.} || $name eq q{..});
    push @sets, $name;
  }
  closedir($ENZDIR);
  return @sets;
}

=head2 set_restriction_enzymes

  $GD->set_restriction_enzymes(-enzyme_set => 'blunts');

or

  $GD->set_restriction_enzymes(-list_path => '/path/to/enzyme_file');

or even

  $GD->set_restriction_enzymes(
    -list_path => '/path/to/enzyme_file',
    -enzyme_set => 'custom_enzymes'
  );

All will return a hash structure full of restriction enzymes.

Tell GeneDesign which set of restriction enzymes to use. If you provide only a
set name with the -enzyme_set flag, GeneDesign will check its config path for a
matching file. Otherwise you must provide a path to a file (and optionally a
name for the set).

=cut

sub set_restriction_enzymes
{
  my ($self, @args) = @_;

  my ($set_name, $set_path)
    = $self->_rearrange([qw(enzyme_set list_path)], @args);

  my $def = 'all_enzymes';
  my $defpath = $self->{conf} . 'enzymes/' . $def;
  $self->{all_enzymes} = _define_sites($defpath);


  if (! $set_name && ! $set_path)
  {
    $self->{enzyme_set} = $self->{all_enzymes};
    $self->{enzyme_set_name} = $def;
  }
  elsif ($set_name && ! $set_path)
  {
    $set_path = $self->{conf} . "enzymes/$set_name";
    if ( ! -e $set_path)
    {
      my $list = join q{, }, $self->list_enzyme_sets();
      my $message = "No enzyme set found that matches $set_name; ";
      $message .= "Options are ($list)\n";
      $self->throw($message);
    }
    my $list = _parse_enzyme_list($set_path);
    my $set = {};
    foreach my $id (@$list)
    {
      if (! exists $self->{all_enzymes}->{$id})
      {
        warn "$id was not recognized as an enzyme... skipping\n";
        next;
      }
      $set->{$id} = $self->{all_enzymes}->{$id};
    }
    $self->{enzyme_set} = $set;
    $self->{enzyme_set_name} = $set_name;
  }
  elsif ($set_path)
  {
    $self->throw("No enzyme list found at $set_path\n")
       unless (-e $set_path);
    my $list = _parse_enzyme_list($set_path);
    my $set = {};
    foreach my $id (@$list)
    {
      if (! exists $self->{all_enzymes}->{$id})
      {
        warn "$id was not recognized as an enzyme... skipping\n";
        next;
      }
      $set->{$id} = $self->{all_enzymes}->{$id};
    }
    $self->{enzyme_set} = $set;
    $self->{enzyme_set_name} = $set_name  || basename($set_path);
  }
  return $self->{enzyme_set};
}

=head2 remove_from_enzyme_set

Removes a subset of enzymes from an enzyme list. This only happens in memory, no
files will be altered. The argument is an array reference of enzyme names.

  $GD->set_restriction_enzymes(-enzyme_set => 'blunts');
  $GD->remove_from_enzyme_set(-enzymes => ['SmaI', 'MlyI']);

NO TEST

=cut

sub remove_from_enzyme_set
{
  my ($self, @args) = @_;

  my ($enzes) = $self->_rearrange([qw(enzymes)], @args);

  return unless ($enzes);

  $self->throw("no enzyme set has been defined")
    unless $self->{enzyme_set};

  my @toremove = ();
  my $ref = ref ($enzes);
  if ($ref eq "ARRAY")
  {
    push @toremove, @$enzes;
  }
  else
  {
    push @toremove, $enzes;
  }
  foreach my $enz (@toremove)
  {
    my $eid = $enz;
    my $eref = ref $enz;
    if ($eref)
    {
      $self->throw("object in enzymes is not a " .
        "Bio::GeneDesign::RestrictionEnzyme object")
        unless ($enz->isa("Bio::GeneDesign::RestrictionEnzyme"));
      $eid = $enz->id;
    }

    if (exists $self->{enzyme_set}->{$eid})
    {
      delete $self->{enzyme_set}->{$eid};
    }
  }
  return;
}

=head2 add_to_enzyme_set

Adds a subset of enzymes to an enzyme list. This only happens in memory, no
files will be altered. The argument is an array reference of RestrictionEnzyme
objects.

  #Grab all known enzymes
  my $allenz = $GD->set_restriction_enzymes(-enzyme_set => 'standard_and_IIB');

  #Pull out a few
  my @keepers = ($allenz->{'BmrI'}, $allenz->{'HphI'});

  #Give GeneDesign the enzyme set you want
  $GD->set_restriction_enzymes(-enzyme_set => 'blunts');

  #Add the few enzymes it didn't have before
  $GD->add_to_enzyme_set(-enzymes => \@keepers);

NO TEST

=cut

sub add_to_enzyme_set
{
  my ($self, @args) = @_;

  my ($enzes) = $self->_rearrange([qw(enzymes)], @args);

  return unless ($enzes);

  $self->throw("no enzyme set has been defined")
    unless $self->{enzyme_set};

  my @toadds = ();
  my $ref = ref ($enzes);
  if ($ref eq "ARRAY")
  {
    push @toadds, @$enzes;
  }
  else
  {
    push @toadds, $enzes;
  }
  foreach my $enz (@toadds)
  {
    $self->throw("object in enzymes is not a " .
      "Bio::GeneDesign::RestrictionEnzyme object")
      unless ($enz->isa("Bio::GeneDesign::RestrictionEnzyme"));

    next if (exists $self->{enzyme_set}->{$enz->id});
    $self->{enzyme_set}->{$enz->id} = $enz;
  }
  return;
}

=head2 restriction_status

=cut

sub restriction_status
{
  my ($self, @args) = @_;

  my ($seq) = $self->_rearrange([qw(sequence)], @args);

  $self->throw("no enzyme set has been defined")
    unless $self->{enzyme_set};

  $self->throw("No arguments provided for set_restriction_enzymes")
    unless ($seq);

  my $str = $self->_stripdown($seq, q{}, 0);
  my @reslist = values %{$self->{enzyme_set}};
  return _define_site_status($str, \@reslist);
}

=head2 build_prefix_tree

Take an array reference of nucleotide sequences (they can be strings, Bio::Seq
objects, or Bio::GeneDesign::RestrictionEnzyme objects) and create a suffix
tree. If you add the peptide flag, the sequences will be ambiguously translated
before they are added to the suffix tree. Otherwise they will be ambiguously
transcribed. It will add the reverse complement of any non peptide sequence as
long as the reverse complement is different.

    my $tree = $GD->build_prefix_tree(-input => ['GGATCC']);

    my $ptree = $GD->build_prefix_tree(
      -input => ['GGCCNNNNNGGCC'],
      -peptide => 1
    );

=cut

sub build_prefix_tree
{
  my ($self, @args) = @_;

  my ($list, $pep) = $self->_rearrange([qw(input peptide)], @args);

  $self->throw("no input provided")
    unless ($list);

  my $tree = Bio::GeneDesign::PrefixTree->new();

  foreach my $seq (@$list)
  {
    my $base = $seq;
    my $id = $seq;
    my $ref = ref($seq);
    if ($ref)
    {
      $self->throw("object in input is not a Bio::Seq, Bio::SeqFeature, or " .
        "Bio::GeneDesign::RestrictionEnzyme object")
        unless ($seq->isa("Bio::Seq")
             || $seq->isa("Bio::SeqFeatureI")
             || $seq->isa("Bio::GeneDesign::RestrictionEnzyme")
      );
      $base = ref($seq->seq)  ? $seq->seq->seq  : $seq->seq;
      $id = $seq->id;
    }

    if ($pep)
    {
      $self->throw('No codon table has been defined')
        unless $self->{codontable};

      my @fpeptides = _amb_translation($base, $self->{codontable},
                                       't', $self->{amb_trans_memo});
      $tree->add_prefix($_, $id, $base) foreach (@fpeptides);

      my $esab = _complement($base, 1);
      my $lagcheck = $esab;
      while (substr($lagcheck, -1) eq "N")
      {
        $lagcheck = substr($lagcheck, 0, length($lagcheck) - 1);
      }
      if ($esab ne $base && $lagcheck eq $esab)
      {
        my @rpeptides = _amb_translation($esab, $self->{codontable},
                                         't', $self->{amb_trans_memo});
        $tree->add_prefix($_, $id, $esab) foreach (@rpeptides);
      }
    }
    else
    {
      my $fnucs = _amb_transcription($base);
      $tree->add_prefix($_, $id, undef) foreach (@$fnucs);

      my $esab = _complement($base, 1);
      if ($esab ne $base)
      {
        my $rnucs = _amb_transcription($esab);
        $tree->add_prefix($_, $id, undef) foreach (@$rnucs);
      }
    }
  }
  return $tree;
}

=head2 search_prefix_tree

Takes a suffix tree and a sequence and searches for results, which are returned
as in the Bio::GeneDesign::PrefixTree documentation.

  my $hits = $GD->search_prefix_tree(-tree => $ptree, -sequence => $mygeneseq);

  # @$hits = (['BamHI', 4, 'GGATCC', 'i hope this didn't pop up'],
  #          ['OhnoI', 21, 'GGCCC', 'I hope these pop up'],
  #          ['WoopsII', 21, 'GGCCC', 'I hope these pop up']
  #);

=cut

sub search_prefix_tree
{
  my ($self, @args) = @_;

  my ($tree, $seq) = $self->_rearrange([qw(tree sequence)], @args);

  $self->throw("no query sequence provided")
    unless ($seq);

  $self->throw("no suffix tree provided")
    unless ($tree);

  $self->throw("tree is not a Bio::GeneDesign::PrefixTree")
    unless ($tree->isa("Bio::GeneDesign::PrefixTree"));

  my $str = $self->_stripdown($seq, q{}, 0);

  my @hits = $tree->find_prefixes($str);

  return \@hits;
}

=head2 pattern_aligner

=cut

sub pattern_aligner
{
  my ($self, @args) = @_;

  my ($seq, $pattern, $peptide, $re)
    = $self->_rearrange([qw(sequence pattern peptide offset)], @args);

  $self->throw("no codon table has been defined")
    unless $self->{codontable};

  $self->throw("no nucleotide sequence provided")
    unless $seq;

  $re = $re || 0;

  my $str = $self->_stripdown($seq, q{}, 1);

  $peptide = $peptide || $self->translate(-sequence => $str);

  my ($newpattern, $offset) = _pattern_aligner($str,
                                               $pattern,
                                               $peptide,
                                               $self->{codontable},
                                               $self->{amb_trans_memo}
  );
  return $re  ? ($newpattern, $offset)  : $newpattern;
}

=head2 pattern_adder

=cut

sub pattern_adder
{
  my ($self, @args) = @_;

  my ($seq, $pattern) = $self->_rearrange([qw(sequence pattern)], @args);

  $self->throw("no codon table has been defined")
    unless $self->{codontable};

  $self->throw("no nucleotide sequence provided")
    unless $seq;

  my $str = $self->_stripdown($seq, q{}, 1);
  my $pat = $self->_stripdown($pattern, q{}, 1);

  my $newsequence = _pattern_adder($str,
                                   $pat,
                                   $self->{codontable},
                                   $self->{reversecodontable},
                                   $self->{amb_trans_memo}
  );
  return $newsequence;
}

=head2 codon_change_type

=cut

sub codon_change_type
{
  my ($self, @args) = @_;

  my ($codold, $codnew) = $self->_rearrange([qw(from to)], @args);

  $self->throw("no codon table has been defined")
    unless $self->{codontable};

  $self->throw("no from sequence provided")
    unless $codold;

  $self->throw("no to sequence provided")
    unless $codnew;

  my $changetype = _codon_change_type($codold, $codnew, $self->{codontable});
  return $changetype;
}

=head2 translate

=cut

sub translate
{
  my ($self, @args) = @_;

  my ($seq, $frame) = $self->_rearrange([qw(sequence frame)], @args);

  $self->throw("no codon table has been defined")
    unless $self->{codontable};

  $self->throw("no nucleotide sequence provided")
    unless $seq;

  my $str = $self->_stripdown($seq, q{}, 1);

  $frame = $frame ? $frame  : 1;

  $self->throw("frame must be -3, -2, -1, 1, 2, or 3")
    if (abs($frame) > 4 || abs($frame) < 0);

  my $peptide = _translate($str, $frame, $self->{codontable});
  if (ref $seq)
  {
    my $newobj = $seq->clone();
    my $desc = $newobj->desc ?  $newobj->desc . q{ } : q{};
    $desc = "translated with " . $self->{organism} . " codon values";
    $newobj->seq($peptide);
    $newobj->alphabet("protein");
    $newobj->desc($desc);
    return $newobj;
  }
  else
  {
    return $peptide;
  }
}

=head2 reverse_translate_algorithms

=cut

sub reverse_translate_algorithms
{
  return Bio::GeneDesign::ReverseTranslate::_list_algorithms();
}

=head2 reverse_translate

=cut

sub reverse_translate
{
  my ($self, @args) = @_;

  my ($pep, $algorithm)
    = $self->_rearrange([qw(
        peptide
        algorithm)], @args);

  $self->throw("no codon table has been defined")
    unless $self->{codontable};

  $self->throw("no RSCU table has been defined")
    unless $self->{rscutable};

  $self->throw("no peptide sequence provided")
    unless $pep;

  my $str = $self->_stripdown($pep, q{}, 1);

  my ($newstr, @baddies) = _sanitize($str, 'pep');
  $str = $newstr;
  if (scalar @baddies)
  {
    print "\nGD_WARNING: removed bad characters (", join q{, }, @baddies;
    print ") from input sequence\n";
  }
  $algorithm = $algorithm || "balanced";
  $algorithm = lc $algorithm;
  $algorithm =~ s{\;}{}xg;
  my $name = "_reversetranslate" . "_" . $algorithm;
  my $subref = \&$name;
  my $seq = &$subref($self->{reversecodontable}, $self->{rscutable}, $str)
    || $self->throw("Can't reverse translate with $algorithm? $!");

  if (ref $pep)
  {
    my $newobj = $pep->clone();
    my $desc = $newobj->desc ?  $newobj->desc . q{ } : q{};
    $desc .= "$algorithm reverse translated with " . $self->{organism};
    $desc .= " RSCU values";
    $newobj->seq($seq);
    $newobj->desc($desc);
    my $CDS = Bio::SeqFeature::Generic->new
    (
      -primary => 'CDS',
      -start => 1,
      -end => length $seq,
      -tag => {
        label => $newobj->id . '_CDS'
      },
    );
    $newobj->add_SeqFeature($CDS) || $self->throw("Cannot add CDS");
    return $newobj;
  }
  else
  {
    return $seq;
  }
}

=head2 codon_juggle_algorithms

=cut

sub codon_juggle_algorithms
{
  return Bio::GeneDesign::CodonJuggle::_list_algorithms();
}

=head2 codon_juggle

=cut

sub codon_juggle
{
  my ($self, @args) = @_;

  my ($seq, $algorithm)
    = $self->_rearrange([qw(
        sequence
        algorithm)], @args);

  $self->throw("no codon table has been defined")
    unless $self->{codontable};

  $self->throw("no RSCU table has been defined")
    unless $self->{rscutable};

  $self->throw("no nucleotide sequence provided")
    unless $seq;

  $self->throw("no algorithm provided")
    unless $algorithm;

  my $str = $self->_stripdown($seq, q{}, 0);

  ##REPLACE THIS WITH CODE THAT GRACEFULLY JUGGLES JUST CDSES OR GENES
  $self->throw("sequence does not appear to be the right length to be a gene")
    unless length($str) % 3 == 0;

  $algorithm = lc $algorithm;
  $algorithm =~ s/\W//xg;
  my $name = "_codonJuggle_" . $algorithm;
  my $subref = \&$name;
  my $newseq = &$subref($self->{codontable},
                        $self->{reversecodontable},
                        $self->{rscutable},
                        $str
  ) || $self->throw("Can't run $algorithm? $!");
  if (ref $seq)
  {
    my $newobj = $seq->clone();
    my $desc = $newobj->desc ?  $newobj->desc . q{ } : q{};
    $desc .= "$algorithm codon juggled with " . $self->{organism};
    $desc .= " RSCU values";
    $newobj->seq($newseq);
    $newobj->desc($desc);
    return $newobj;
  }
  else
  {
    return $newseq;
  }
}

=head2 subtract_sequence

=cut

sub subtract_sequence
{
  my ($self, @args) = @_;

  my ($seq, $rem) = $self->_rearrange([qw(sequence remove)], @args);

  $self->throw("no codon table has been defined")
    unless $self->{codontable};

  $self->throw("no RSCU table has been defined")
    unless $self->{rscutable};

  $self->throw("no nucleotide sequence provided")
    unless $seq;

  $self->throw("no sequence to be removed was defined")
    unless ($rem);

  my $str = $self->_stripdown($seq, q{}, 0);

  my $regarr;
  my $less = $rem;
  if (ref($rem))
  {
    if ($rem->isa("Bio::Seq") || $rem->isa("Bio::SeqFeatureI"))
    {
      $less = ref($rem->seq) ? $rem->seq->seq  : $rem->seq;
      $regarr = _regarr($less, 1);
    }
    elsif ($rem->isa("Bio::GeneDesign::RestrictionEnzyme"))
    {
      $less = $rem->seq;
      $regarr = $rem->regex;
    }
    else
    {
      $self->throw("removal argument is not a Bio::Seq, Bio::SeqFeature, or "
        . "Bio::GeneDesign::RestrictionEnzyme");
    }
  }
  else
  {
    $regarr = _regarr($less, 1);
  }

  my $newseq = _subtract( uc $str,
                          uc $less,
                          $regarr,
                          $self->{codontable},
                          $self->{rscutable},
                          $self->{reversecodontable}
  );

  if (ref $seq)
  {
    my $newobj = $seq->clone();
    my $desc = $newobj->desc ?  $newobj->desc . q{ } : q{};
    $desc .= $rem->id . " subtracted with " . $self->{organism};
    $desc .= " RSCU values";
    $newobj->seq($newseq);
    $newobj->desc($desc);
    return $newobj;
  }
  else
  {
    return $newseq;
  }
}

=head2 repeat_smash

=cut

sub repeat_smash
{
  my ($self, @args) = @_;

  my ($seq) = $self->_rearrange([qw(sequence)], @args);

  $self->throw("no codon table has been defined")
    unless $self->{codontable};

  $self->throw("no RSCU table has been defined")
    unless $self->{rscutable};

  $self->throw("no nucleotide sequence provided")
    unless $seq;

  my $str = $self->_stripdown($seq, q{}, 0);


  my $newseq = _minimize_local_alignment_dp
  (
    $str,
    $self->{codontable},
    $self->{reversecodontable},
    $self->{rscutable}
  );
  if (ref $seq)
  {
    my $newobj = $seq->clone();
    my $desc = $newobj->desc ?  $newobj->desc . q{ } : q{};
    $desc .= $seq->id . " repeat smashed with " . $self->{organism};
    $desc .= " RSCU values";
    $newobj->seq($newseq);
    $newobj->desc($desc);
    return $newobj;
  }
  else
  {
    return $newseq;
  }
}

=head2 make_amplification_primers

NO TEST

=cut

sub make_amplification_primers
{
  my ($self, @args) = @_;

  my ($seq, $temp) = $self->_rearrange([qw(sequence temperature)], @args);

  $self->throw("no sequence provided") unless ($seq);
  $temp = $temp || 60;

  my $str = $self->_stripdown($seq, q{}, 0);

  return _make_amplification_primers($str, $temp);
}

=head2 contains_homopolymer

Returns 1 if the sequence contains a homopolymer of the provided length (default
is 5bp) and 0 else

=cut

sub contains_homopolymer
{
  my ($self, @args) = @_;

  my ($seq, $length) = $self->_rearrange([qw(sequence length)], @args);

  $self->throw("no sequence provided") unless ($seq);
  $length = $length || 5;

  my $str = $self->_stripdown($seq, q{}, 0);

  return _check_for_homopolymer($str, $length);
}

=head2 filter_homopolymers

=cut

sub filter_homopolymers
{
  my ($self, @args) = @_;

  my ($seqs, $length) = $self->_rearrange([qw(sequences length)], @args);

  $self->throw("no argument provided to filter_homopolymers")
    unless $seqs;
  $length = $length || 5;

  my $arrref = $self->_stripdown($seqs, 'ARRAY', 1);

  my $seqarr = _filter_homopolymer( $arrref, $length);
  return $seqarr;
}

=head2 find_runs

=cut

sub find_runs
{
  my ($self, @args) = @_;

  my ($seq, $pattern, $min) = $self->_rearrange([qw(
    sequence pattern minimum)], @args);
  
  if (! $pattern)
  {
    $self->throw("no pattern argument provided to find_runs");
  }
  $min = $min || 5;
  
  return _find_runs($seq, $pattern, $min);
}

=head2 make_graph

=cut

sub make_graph
{
  my ($self, @args) = @_;

  $self->throw("Graphing is not available")
    unless $self->{graph};

  my ($seqobjs, $window)
    = $self->_rearrange([qw(sequences window)], @args);

  $self->throw("no codon table has been defined")
    unless $self->{codontable};

  $self->throw("no RSCU table has been defined")
    unless $self->{rscutable};

  $self->throw("no nucleotide sequences provided")
    unless $seqobjs;

  $self->throw("sequences argument is not an array reference")
    unless ref($seqobjs) eq "ARRAY";

  foreach my $seqobj (@$seqobjs)
  {
    $self->throw(ref($seqobj) . " is not a Bio::Seq object")
      unless $seqobj->isa("Bio::Seq");

    $self->throw("$seqobj is not a nucleotide sequence")
      unless $seqobj->alphabet eq "dna";
  }

  my ($graph, $format) = _make_graph( $seqobjs,
                                      $window,
                                      $self->{organism},
                                      $self->{codontable},
                                      $self->{rscutable},
                                      $self->{reversecodontable});
  return ($graph, $format);
}

=head2 make_dotplot

=cut

sub make_dotplot
{
  my ($self, @args) = @_;

  $self->throw("Graphing is not available")
    unless $self->{graph};

  my ($seq1, $seq2, $window, $stringency)
    = $self->_rearrange([qw(first second window stringency)], @args);

  $window = $window || 10;
  $stringency = $stringency || 10;

  $self->throw("no nucleotide sequences provided")
    unless ($seq1 && $seq2);

  foreach my $seqobj ($seq1, $seq2)
  {
    $self->throw(ref($seqobj) . " is not a Bio::Seq object")
      unless $seqobj->isa("Bio::Seq");

    $self->throw("$seqobj is not a nucleotide sequence")
      unless $seqobj->alphabet eq "dna";
  }

  my $graph = _dotplot(
    $seq1->seq,
    $seq2->seq,
    $window,
    $stringency
  );
  return $graph;
}

=head2 import_seqs

NO TEST

=cut

sub import_seqs
{
  my ($self, $path) = @_;
  $self->throw("$path does not exist.") if (! -e $path);
  my ($iterator, $filename, $suffix) = _import_sequences($path);
  return ($iterator, $filename, $suffix);
}
=head2 import_seq_from_string

NO TEST

=cut

sub import_seq_from_string
{
  my ($self, $string) = @_;
  my ($iterator, $filename, $suffix) = _import_sequences_from_string($string);
  return ($iterator, $filename, $suffix);
}

=head2 export_formats

Export formats that have been tried and tested to work well.

=cut

sub export_formats
{
  return Bio::GeneDesign::IO::_export_formats();
}

=head2 export_seqs

NO TEST

=cut

sub export_seqs
{
  my ($self, @args) = @_;

  my ($outpath, $outformat, $seqarr)
    = $self->_rearrange([qw(
        filepath
        format
        sequences)], @args);

  $outformat = $outformat ? $outformat : 'genbank';
  $self->throw("$outformat is not a format recognized by BioPerl")
    if (! _isa_BP_format($outformat));

  #Long attributes that come in from a genbank file will have corruption
  #remove spaces and reattribute to fix bbs in genbank file ):
  _long_att_fix($seqarr) if ($outformat eq 'genbank');
  
  return _export_sequences($outpath, $outformat, $seqarr);
}

=head2 random_dna

=cut

sub random_dna
{
  my ($self, @args) = @_;

  my ($rlen, $rgc, $rstop)
    = $self->_rearrange([qw(
        length
        gc_percentage
        no_stops)], @args);

  $self->throw("no codon table has been defined")
    if ($rstop && ! $self->{codontable});

  $rgc = $rgc || 50;
  $self->throw("gc_percentage must be between 0 and 100")
    if ($rgc && ($rgc < 0 || $rgc > 100));

  if (! $rlen || $rlen < 1)
  {
    return q{};
  }
  elsif ($rlen == 1)
  {
    return $rgc ? _randombase_weighted($rgc)  : _randombase;
  }
  return _randomDNA($rlen, $rgc, $rstop, $self->{codontable});
}

=head2 replace_ambiguous_bases

=cut

sub replace_ambiguous_bases
{
  my ($self, $seq) = @_;

  $self->throw("no sequence provided ")
    unless ($seq);

  my $str = $self->_stripdown($seq, q{}, 1);

  my $newstr = _replace_ambiguous_bases($str);

  if (ref $seq)
  {
    my $newobj = $seq->clone();
    my $desc = $newobj->desc ?  $newobj->desc . q{ } : q{};
    $desc .= "deambiguated";
    $newobj->seq($newstr);
    $newobj->desc($desc);
    return $newobj;
  }
  else
  {
    return $newstr;
  }
}

=head1 PLEASANTRIES

=head2 pad

    my $name = 5;
    my $nice = $GD->pad($name, 3);
    $nice == "005" || die;

    $name = "oligo";
    $nice = $GD->pad($name, 7, "_");
    $nice == "__oligo" || die;

Pads an integer with leading zeroes (by default) or any provided set of
characters. This is useful both to make reports pretty and to standardize the
length of designations.

=cut

sub pad
{
  my ($self, $num, $thickness, $chars) = @_;
  my $t = $num;
  $chars = $chars || "0";
  $t = $chars . $t while (length($t) < $thickness);
  return $t;
}

=head2 attitude

    my $adverb = $GD->attitude();

Ask GeneDesign how it handled your request.

=cut

sub attitude
{
  my @adverbs = qw(Elegantly Energetically Enthusiastically Excitedly Daintily
    Deliberately Diligently Dreamily Courageously Cooly Cleverly Cheerfully
    Carefully Calmly Briskly Blindly Bashfully Absentmindedly Awkwardly
    Faithfully Ferociously Fervently Fiercely Fondly Gently Gleefully Gratefully
    Gracefully Happily Helpfully Heroically Honestly Joyfully Jubilantly
    Jovially Keenly Kindly Knowingly Kookily Loftily Lovingly Loyally
    Majestically Mechanically Merrily Mostly Neatly Nicely Obediently Officially
    Optimistically Patiently Perfectly Playfully Positively Powerfully
    Punctually Properly Promptly Quaintly Quickly Quirkily Rapidly Readily
    Reassuringly Righteously Sedately Seriously Sharply Shyly Silently Smoothly
    Solemnly Speedily Strictly Successfully Suddenly Sweetly Swiftly Tenderly
    Thankfully Throroughly Thoughtfully Triumphantly Ultimately Unabashedly
    Utterly Upliftingly Urgently Usefully Valiantly Victoriously Vivaciously
    Warmly Wholly Wisely Wonderfully Yawningly Zealously Zestfully
  );
  my $index = _random_index(scalar(@adverbs));
  return $adverbs[$index];
}

=head2 endslash

=cut

sub endslash
{
  my ($self, $path) = @_;
  if ((substr $path, -1, 1) ne q{/})
  {
    $path .= q{/};
  }
  return $path;
}

=head2 _stripdown

=cut

sub _stripdown
{
  my ($self, $seqarg, $type, $enz_allowed) = @_;

  $enz_allowed = $enz_allowed || 0;
  my @seqs = ref $seqarg eq 'ARRAY' ? @$seqarg  : ($seqarg);
  my @list;
  foreach my $seq (@seqs)
  {
    my $str = $seq;
    my $ref = ref $seq;
    if ($ref)
    {
      my $bit = $self->_checkref($seq, $enz_allowed);
      $self->throw("object $ref is not a compatible object $bit") if ($bit < 1);
      $str = ref $seq->seq  ? $seq->seq->seq  : $seq->seq;
    }
    push @list, uc $str;
  }
  return \@list if ($type eq 'ARRAY');
  return $list[0];
}

=head2 _checkref

=cut

sub _checkref
{
  my ($self, $pobj, $enz_allowed) = @_;
  my $ref = ref $pobj;
  return -1 if (! $ref);
  $enz_allowed = $enz_allowed || 0;
  my ($bioseq, $bioseqfeat) = (0, 0);
  $bioseq = $pobj->isa("Bio::Seq");
  $bioseqfeat = $pobj->isa("Bio::SeqFeatureI");
  if ($enz_allowed)
  {
    $enz_allowed = $pobj->isa("Bio::GeneDesign::RestrictionEnzyme");
  }
  return $bioseq + $bioseqfeat + $enz_allowed;
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, Sarah Richardson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Lawrence Berkeley
National Laboratory, the Department of Energy, and the GeneDesign developers may
not be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE DEVELOPERS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut