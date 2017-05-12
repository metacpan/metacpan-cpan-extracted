#
# GeneDesign module for restriction enzyme handing
#

=head1 NAME

Bio::GeneDesign::RestrictionEnzyme

=head1 VERSION

Version 5.54

=head1 DESCRIPTION

GeneDesign object that represents a type II restriction enzyme

=head1 AUTHOR

Sarah Richardson <SMRichardson@lbl.gov>

=cut

package Bio::GeneDesign::RestrictionEnzyme;

use Bio::GeneDesign::Basic qw(:GD);
use Carp;

use strict;
use warnings;

use base qw(Bio::Root::Root);

our $VERSION = 5.54;

my $IIPreg  = qr/   ([A-Z]*)   \^ ([A-Z]*)      /x;
my $IIAreg  = qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x;
my $IIBreg  = qr/\A\(([\-]*\d+) \/ ([\-]*\d+)\) \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x;

my %RE_vendors = (
  B => "Invitrogen", C => "Minotech", E => "Stratagene Agilent",
  F => "Thermo Scientific Fermentas", I => "SibEnzyme", J => "Nippon Gene Co.",
  K => "Takara", M => "Roche Applied Science", N => "New England Biolabs",
  O => "Toyobo Technologies", Q => "Molecular Biology Resources",
  R => "Promega", S => "Sigma Aldrich", U => "Bangalore Genei", V => "Vivantis",
  X => "EURx", Y => "CinnaGen"
);

my %methtrans = (b => "blocked", blocked => "blocked",
                 i => "inhibited", inhibited => "inhibited",
                 u => "unknown", unknown => "unknown"
);

=head1 CONSTRUCTOR METHODS

=head2 new

You can create a new enzyme or clone an existing enzyme to create a new instance
of an abstract enzyme definition. To do this, provide the -enzyme flag; the
constructor will ignore every other argument except for -start.

Required arguments:

    EITHER

        -enzyme : a Bio::GeneDesign::RestrictionEnzyme object to clone

    OR
        -id     : The name of the enzyme (i.e., BamHI)
        -cutseq : The string describing the enzyme's recognition and cleavage
                  site

Optional arguments:

        -temp     : The incubation temperature for the enzyme
        -tempin   : The heat inactivation temperature for the enzyme
        -score    : A float score, usually the price of the enzyme in dollars
        -methdam  : Sensitivity to dam methylation; can take the values
                      b or blocked,
                      i or inhibited,
                      u or unknown,
                    if undefined, will take the value indifferent.
        -methdcm  : Sensitivity to dcm methylation; can take the values
                      b or blocked,
                      i or inhibited,
                      u or unknown,
                    if undefined, will take the value indifferent.
        -methcpg  : Sensitivity to cpg methylation; can take the values
                      b or blocked,
                      i or inhibited,
                      u or unknown,
                    if undefined, will take the value indifferent.
        -vendors  : a string of single letter codes that represent vendor
                    availability - no spaces.  see vendor() for a list of the
                    codes.
        -staract  : Whether or not the enzyme exhibits star activity - 1 or 0.
        -buffers  : a hash reference; keys are buffer names and values are the
                    enzyme activity in that buffer. For example:
                    NEB1 => 50, NEB2 => 100, etc.
        -start    : An integer representing an offset; usually used only in
                    cloned instances, as opposed to abstract instances.
        -exclude  : An arrayref full of ids for enzymes that should be
                    considered mutually exclusive to this enzyme - see exclude()

=cut

sub new
{
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);

  my ($object, $id, $cutseq, $temp, $tempin, $score, $methdam, $methdcm,
      $methcpg, $vendors, $staract, $buffers, $start, $exclude, $aggress) =
     $self->_rearrange([qw(ENZYME ID CUTSEQ TEMP TEMPIN SCORE METHDAM METHDCM
       METHCPG VENDORS STARACT BUFFERS START EXCLUDE AGGRESS)], @args);

  if ($object)
  {
    $self->throw("object of class " . ref($object) . " does not implement ".
        "Bio::GeneDesign::RestrictionEnzyme.")
      unless $object->isa("Bio::GeneDesign::RestrictionEnzyme");
    $self = $object->clone();
  }
  else
  {

    $self->throw("No enzyme id defined") unless ($id);
    $self->{id} = $id;

    $self->throw("No cut sequence defined") unless ($cutseq);
    $self->{cutseq} = $cutseq;

    my $recseq = $cutseq;
    $recseq =~ s/\W*\d*//xg;
    $self->{recseq} = $recseq;

    #Regular expression arrayref to use for enzyme searching
    #Should store as compiled regexes instead
    $self->{regex} = _regarr($recseq);

    my $sitelen = length($recseq);
    $self->{length} = $sitelen;

    #Enzyme Class and Palindromy
    my ($lef, $rig) = (q{}, q{});
    if ($cutseq =~ $IIPreg)
    {
      $lef = length($1);
      $rig = length($2);
      $self->{class} = "IIP";
      $self->{classex} = $IIPreg;

      if ($lef == $rig)
      {
        $self->{palindromy} = "unknown";
      }
      else
      {
        my $inlef = $lef;
        $inlef = length($recseq) - $inlef if ($inlef > (.5 * length($recseq)));
        my $mattersbit = substr($recseq, $inlef, length($recseq) - (2 * $inlef));
        if ($mattersbit && $mattersbit =~ $ambnt && length($mattersbit) % 2 == 0)
        {
          $self->{palindromy} = "pnon";
        }
        elsif ($mattersbit && $mattersbit eq _complement($mattersbit, 1))
        {
          $self->{palindromy} = "pal";
        }
        elsif ($mattersbit)
        {
          $self->{palindromy} = "nonpal";
        }
      }
    }
    elsif ($cutseq =~ $IIBreg)
    {
      $lef = int($1);
      $rig = int($2);
      $self->{class} = "IIB";
      $self->{classex} = $IIBreg;
      $self->{palindromy} = "pnon";
    }
    elsif ($cutseq =~ $IIAreg)
    {
      $lef = int($1);
      $rig = int($2);
      $self->{class} = "IIA";
      $self->{classex} = $IIAreg;
      $self->{palindromy} = "pnon";
    }
    else
    {
      $self->{class} = "unknown";
    }

    #Enzyme type
    my $type;
    if ($lef < $rig)
    {
      $type .= "5'";
      $self->{inside_cut} = $lef;
      $self->{outside_cut} = $rig;
    }
    elsif ($lef > $rig)
    {
      $type .= "3'";
      $self->{inside_cut} = $rig;
      $self->{outside_cut} = $lef;
    }
    elsif ($lef == $rig)
    {
      $type .= 'b';
    }
    $self->{onebpoverhang} = 1 if (abs($lef - $rig) == 1);
    $self->{type} = $type;

    $self->{temp} = $temp if ($temp);
    if ($tempin)
    {
      my ($intime, $intemp) = split q{@}, $tempin;
      $self->{tempin} = $intemp;
      $self->{timein} = $intime;
    }

    $self->{score} = $score if ($score);
    $self->{aggress} = $aggress;

    $self->{staract} = 1 if ($staract);

    if (exists $methtrans{$methdam})
    {
      $self->{methdam} = $methtrans{$methdam};
    }
    else
    {
      $self->{methdam} = 'indifferent';
    }

    if (exists $methtrans{$methdcm})
    {
      $self->{methdcm} = $methtrans{$methdcm};
    }
    else
    {
      $self->{methdcm} = 'indifferent';
    }

    if (exists $methtrans{$methcpg})
    {
      $self->{methcpg} = $methtrans{$methcpg};
    }
    else
    {
      $self->{methcpg} = 'indifferent';
    }

    if ($vendors)
    {
      my %vhsh = ();
      foreach my $v (split(q{}, $vendors))
      {
        $vhsh{$v} = $RE_vendors{$v} if (exists $RE_vendors{$v});
        carp("$v not in vendor list!") unless (exists $RE_vendors{$v});
      }
      $self->{vendors} = \%vhsh;
    }

    $self->{buffers} = $buffers if ($buffers);
  }

  $self->{start} = $start if ($start);

  $self->{exclude} = $exclude if ($exclude);

  return $self;
}

=head1 FUNCTIONAL METHODS

=head2 clone

By default in GeneDesign code, RestrictionEnzyme objects are meant to stand as
abstracts - that is, they stand for BamHI in general, and not for a particular
instance of a BamHI recognition site. If you want to use the objects in the
latter sense, you will need to clone the abstract object instantiated when the
definition file is read in, thus generating an arbitrary number of BamHI
instances that can then be differentiated by their start attributes.

=cut

sub clone
{
   my ($self) = @_;
   my $copy;
   foreach my $key (keys %{$self})
   {
    $copy->{$key} = $self->{$key};
   }
   bless $copy, ref $self;
   return $copy;
}

=head2 positions

Generates a hash describing the positions of the enzyme's recognition
sites in a nucleotide sequence. Keys are offset in nucleotides, and values are
the recognition site found at said offset as a string.

=cut

sub positions
{
  my ($self, $seq) = @_;
  my $total = {};
  foreach my $sit (@{$self->{regex}})
  {
    while ($seq =~ /(?=($sit))/ixg)
    {
      $total->{pos $seq} = $1;
    }
  }
  return $total;
}

=head2 overhang

Given a nucleotide sequence context, what overhang does this enzyme leave, and
how far away from the cutsite is it?

Arguments:

=cut

sub overhang
{
  my ($self, $dna, $context, $strand) = @_;
  my ($ohangstart, $mattersbit) = (0, q{});
  my $lef;
  my $rig;
  if ($self->{class} eq "IIP")
  {
    ($lef, $rig) = (length($1), length($2)) if ($self->{cutseq} =~ $IIPreg);
    ($lef, $rig) = ($rig, $lef) if ($rig < $lef);
    $ohangstart = $lef + 1;
    $mattersbit = substr($dna, $ohangstart-1, $rig-$lef);
  }
  elsif ($self->{class} eq "IIA")
  {
    ($lef, $rig) = ($1, $2) if ($self->{cutseq} =~ $IIAreg);
    ($lef, $rig) = ($rig, $lef) if ($rig < $lef);
    if ($strand == 1)
    {
      $ohangstart = length($dna) + $lef + 1;
    }
    else
    {
      $ohangstart = length($context) - length($dna) - $rig + 1;
    }
    $mattersbit = substr($context, $ohangstart-1, $rig-$lef);
    $ohangstart = $strand == 1  ? length($dna) + $lef :   0 - ($rig);
  }
  else
  {
    return ();
  }
  return ($ohangstart, $mattersbit);
}

=head2 display

Generates a tab delimited display string that can be used to print enzyme
information out in a tabular format.

=cut

sub display
{
  my ($self) = @_;
  my $staract = $self->{staract}  ? "*" : q{};
  my (@blocked, @inhibed) = ((), ());
  push @blocked, "cpg" if ($self->{methcpg} eq "blocked");
  push @blocked, "dam" if ($self->{methdam} eq "blocked");
  push @blocked, "dcm" if ($self->{methdcm} eq "blocked");
  push @inhibed, "cpg" if ($self->{methcpg} eq "inhibited");
  push @inhibed, "dam" if ($self->{methdam} eq "inhibited");
  push @inhibed, "dcm" if ($self->{methdcm} eq "inhibited");
  my $buffstr = undef;
  foreach (sort keys %{$self->{buffers}})
  {
    $buffstr .= "$_ (" . $self->{buffers}->{$_} . ") " if ($self->{buffers}->{$_});
  }
  my $vendstr = join(", ", values %{$self->{vendors}});
  my $display = undef;
  my $inact = $self->{tempin} ? " (". $self->{timein} . q{@} . $self->{tempin} . ")" : q{};
  $display .= $self->{id} . "\t";
  $display .= $self->{cutseq} . $staract . "\t";
  $display .= $self->{type} . "\t";
  $display .= $self->{start} . "\t" if ($self->{start});
  $display .= $self->{temp} . $inact . "\t";
  $display .= join(", ", @blocked) . "\t";
  $display .= join(", ", @inhibed) . "\t";
  $display .= $self->{score} . "\t";
  $display .= $buffstr . "\t";
  $display .= $vendstr . "\t";
  return $display;
}

=head2 common_buffers

Returns an array reference listing the buffers, if any, in which two enzymes
both have 100% activity. in boolean mode returns the number of buffers

=cut

sub common_buffers
{
  my ($self, $buddy, $bool) = @_;
  $self->throw("Argument is not a Bio::GeneDesign::RestrictionEnzyme")
    unless $buddy->isa("Bio::GeneDesign::RestrictionEnzyme");

  my $sbuffs = $self->{buffers};
  my $bbuffs = $buddy->{buffers};
  my @answer;
  foreach my $skey (sort keys %{$sbuffs})
  {
    my $sval = $sbuffs->{$skey};
    my $bval = $bbuffs->{$skey};
    if ($skey eq "Other" && $sval && $bval && "$sval" eq "$bval")
    {
      push @answer, $skey;
    }
    elsif ($sval && $bval && "$sval" == 100 && "$bval" == 100)
    {
      push @answer, $skey;
    }
  }
  return $bool  ? scalar(@answer)  : \@answer;
}

=head2 acceptable_buffer

Returns a buffer in which both enzymes will have at least a thresholded amount
of activity.

=cut

sub acceptable_buffer
{
  my ($self, $buddy, $level) = @_;
  $self->throw("Argument is not a Bio::GeneDesign::RestrictionEnzyme")
    unless $buddy->isa("Bio::GeneDesign::RestrictionEnzyme");

  $level = $level || 75;
  my $sbuffs = $self->{buffers};
  my $bbuffs = $buddy->{buffers};
  my %answers;
  foreach my $skey (sort keys %{$sbuffs})
  {
    my $sval = $sbuffs->{$skey};
    my $bval = $bbuffs->{$skey};
    if ($skey eq "Other" && $sval && $bval && $sval == $bval)
    {
      $answers{$skey} = 200;
    }
    elsif ($sval && $bval && $sval >= $level && $bval >= $level)
    {
      $answers{$skey} = $sval + $bval;
    }
  }
  my @keys = sort {$answers{$b} <=> $answers{$a} && $b cmp $a} keys %answers;
  return scalar @keys  ? $keys[0]  : undef;
}

=head2 units

Returns the number of units needed to cleave some sequence

=cut

sub units
{
  my ($self, @args) = @_;

  my ($buffer, $sequence) = $self->_rearrange([qw(buffer sequence)], @args);


  my $poshsh = $self->positions($sequence);
  my $count = scalar keys %{$poshsh};

  my $freq = $count / (length $sequence);

  my $aggr = $self->aggress() || .000001;
  $aggr = 1 / $aggr;

  $buffer = $buffer || $self->acceptable_buffer($self, 100);
  my $buff = $self->buffers->{$buffer} || 1;
  my $jad = $buff / 100;
  my $adj = $jad > 0  ? 1 / $jad : 0;

  my $units = sprintf("%.1f", $freq * $aggr * $adj);

  return $units;
}


=head1 FILTERING METHODS

=head2 filter_by_sequence

  Arguments: an arrayref of string nucleotide sequences (may be ambiguous)
             a flag indicating whether or not the sequences in the array are
              required (1 means they must NOT match; default 0 means they must
              match)

  Returns : 1 if the enzyme passes;
            0 if the enzyme fails.

=cut

sub filter_by_sequence
{
  my ($self, $arrref, $req) = @_;
  $req = 0 if (! $req);
  my $result = 1;
  foreach my $seq (@$arrref)
  {
    my $regex = _regres($seq, 1);
    if ($regex =~ /\[ X \]/x)
    {
      print "\tWARNING: Cannot parse sequence $seq containing non-nucleotide "
        . "characters - ignoring.\n";
      next;
    }
    $result = 0 if ( $req == 1 && $self->{recseq} =~ $regex );
    $result = 0 if ( $req == 0 && $self->{recseq} !~ $regex );
  }
  return $result;
}

=head2 filter_by_score

  Arguments : a float

  Returns   : 1 if the enzyme's score is less than or equal to the argument,
              0 if the enzyme's score is higher.

=cut

sub filter_by_score
{
  my ($self, $score) = @_;
  my $result = 1;
  $result = 0 if ($self->{score} > $score);
  return $result;
}

=head2 filter_by_vendor

  Arguments : an arrayref of vendor abbreviations; see vendor().

  Returns   : 1 if the enzyme is supplied by any of the vendors queried,
              0 else.

=cut

sub filter_by_vendor
{
  my ($self, $vendlist) = @_;
  my $result = 1;
  my $flag = 0;
  foreach my $vend (@$vendlist)
  {
    unless (exists($RE_vendors{$vend}))
    {
      print "\tWARNING: Cannot parse vendor argument $vend - ignoring.\n";
      next;
    }
    $flag++ if ( exists( $self->{vendors}->{$vend} ) );
  }
  $result = $flag == 0 ? 0 : 1;
  return $result;
}

=head2 filter_by_buffer_activity

  Arguments : a hashref of buffer thresholds; the key is the buffer name, the
                value is an activity threshold.

  Returns   : 1 if the enzyme meets all the buffer requirements,
              0 else.

=cut

sub filter_by_buffer_activity
{
  my ($self, $hshref) = @_;
  my $result = 1;
  my $rebuff = $self->{buffers};
  foreach my $buff (keys %$hshref)
  {
    my $val = $hshref->{$buff};
    $result = 0 if ( ! exists($rebuff->{$buff}) || $rebuff->{$buff} < $val );
  }

  return $result;
}

=head2 filter_by_dcm_sensitivity

  Arguments : an arrayref of sensitivity values; the key is the sensitivity
                blocked, inhibited, or indifferent

  Returns   : 1 if the enzyme meets the dcm sensitivity requirements,
              0 else.

=cut

sub filter_by_dcm_sensitivity
{
  my ($self, $arrref) = @_;
  my $result = 1;
  my %sensehsh;
  foreach my $sense (@$arrref)
  {
    if ($sense ne "blocked" && $sense ne "inhibited" && $sense ne "indifferent")
    {
      $sense = lc $sense;
      print "\tWARNING: Cannot parse dcmsense argument $sense - ignoring.\n";
      next;
    }
    $sensehsh{$sense}++;
  }
  $result = 0 unless ( exists($sensehsh{$self->{methdcm}}) );
  return $result;
}

=head2 filter_by_dam_sensitivity

  Arguments : an arrayref of sensitivity values; the key is the sensitivity
                blocked, inhibited, or indifferent

  Returns   : 1 if the enzyme meets the dam sensitivity requirements,
              0 else.

=cut

sub filter_by_dam_sensitivity
{
  my ($self, $arrref) = @_;
  my $result = 1;
  my %sensehsh;
  foreach my $sense (@$arrref)
  {
    if ($sense ne "blocked" && $sense ne "inhibited" && $sense ne "indifferent")
    {
      $sense = lc $sense;
      print "\tWARNING: Cannot parse damsense argument $sense - ignoring.\n";
      next;
    }
    $sensehsh{$sense}++;
  }
  $result = 0 unless ( exists($sensehsh{$self->{methdam}}) );
  return $result;
}

=head2 filter_by_cpg_sensitivity

  Arguments : an arrayref of sensitivity values; the key is the sensitivity
                blocked, inhibited, or indifferent

  Returns   : 1 if the enzyme meets the cpg sensitivity requirements,
              0 else.

=cut

sub filter_by_cpg_sensitivity
{
  my ($self, $arrref) = @_;
  my $result = 1;
  my %sensehsh;
  foreach my $sense (@$arrref)
  {
    if ($sense ne "blocked" && $sense ne "inhibited" && $sense ne "indifferent")
    {
      $sense = lc $sense;
      print "\tWARNING: Cannot parse cpgsense argument $sense - ignoring.\n";
      next;
    }
    $sensehsh{$sense}++;
  }
  $result = 0 unless ( exists($sensehsh{$self->{methcpg}}) );
  return $result;
}

=head2 filter_by_star_activity

  Arguments : 1 if star activity required, 0 else

  Returns   : 1 if the enzyme meets the star activity requirements,
              0 else.

=cut

sub filter_by_star_activity
{
  my ($self, $star) = @_;
  my $result = 1;
  $star = 0 unless ($star);
  $result = 0 if (($star && ! $self->{staract}) || (! $star && $self->{staract}));
  return $result;
}

=head2 filter_by_incubation_temperature

  Arguments : an arrayref of acceptable integer incubation temperatures

  Returns   : 1 if the enzyme meets the incubation temperature requirements,
              0 else.

=cut

sub filter_by_incubation_temperature
{
  my ($self, $arrref) = @_;
  my $result = 1;
  my %temps;
  foreach my $temp (@$arrref)
  {
    if ($temp !~ /\d/x || $temp <= 0)
    {
      print "\tWARNING: Cannot parse incubation argument $temp - ignoring.\n";
    }
    $temps{$temp}++;
  }
  $result = 0 unless ( exists $temps{$self->{temp}});
  return $result;
}

=head2 filter_by_inactivation_temperature

  Arguments : an acceptable integer inactivation temperature maximum

  Returns   : 1 if the enzyme meets the inactivation temperature requirement,
              0 else.

=cut

sub filter_by_inactivation_temperature
{
  my ($self, $temp) = @_;
  my $result = 1;
  if ($temp !~ /\d/x || $temp <= 0)
  {
    print "\tWARNING: Cannot parse inactivation argument $temp - ignoring.\n";
  }
  else
  {
    $result = 0 if ($self->{tempin} > $temp);
  }
  return $result;
}

=head2 filter_by_base_ambiguity

  Arguments : "nonNonly" if any non N bases are allowed; "ATCGonly" if only
                A, T, C, or G are allowed

  Returns   : 1 if the enzyme meets the ambiguous nucleotide requirement,
              0 else.

=cut

sub filter_by_base_ambiguity
{
  my ($self, $ambig) = @_;
  my $result = 1;
  if ($ambig ne "nonNonly" && $ambig ne "ATCGonly")
  {
    print "\tWARNING: Cannot parse ambiguity argument $ambig - ignoring.\n";
  }
  else
  {
    my $ambregex;
    $ambregex  = qr/N/  if ($ambig eq "nonNonly");
    $ambregex  = $ambnt  if ($ambig eq "ATCGonly");
    $result = 0 unless ( $self->{recseq} =~ $ambregex );
  }
  return $result;
}

=head2 filter_by_length

  Arguments : an arrayref of acceptable recognition site lengths

  Returns   : 1 if the enzyme meets the recognition site length requirements,
              0 else.

=cut

sub filter_by_length
{
  my ($self, $arrref) = @_;
  my $result = 1;
  my %lens;
  foreach my $len (@$arrref)
  {
    if ($len =~ /\D/x || $len <= 0)
    {
      print "\tWARNING: Cannot parse length argument $len - ignoring.\n";
      next;
    }
    $lens{$len}++;
  }
  $result = 0 unless ( exists $lens{length($self->{recseq})} );
  return $result;
}

=head2 filter_by_overhang_palindromy

  Arguments : an arrayref of acceptable overhang palindromys, from the list
                pal (palindromic),
                nonpal (nonpalindromic),
                pnon (potentially nonpalindromic)

  Returns   : 1 if the enzyme meets the palindromy requirements,
              0 else.

=cut

sub filter_by_overhang_palindromy
{
  my ($self, $arrref) = @_;
  my $result = 1;
  my %pals;
  foreach my $pal (@$arrref)
  {
    if ($pal ne "pal" && $pal ne "pnon" && $pal ne "nonpal")
    {
      print "\tWARNING: Cannot parse palindromy argument $pal - ignoring.\n";
      next;
    }
    $pals{$pal}++;
  }
  $result = 0 unless (exists $pals{$self->{palindromy}});
  return $result;
}

=head2 filter_by_stickiness

  Arguments : an arrayref of acceptable overhang orientations, from the list
                1 (single basepair overhang),
                5 (five prime overhang),
                3 (three prime overhang),
                b (blunt ended)

  Returns   : 1 if the enzyme meets the overhang requirements,
              0 else.

=cut

sub filter_by_stickiness
{
  my ($self, $arrref) = @_;
  my $result = 1;
  my %sticks;
  foreach my $stick (@$arrref)
  {
    if ($stick ne "5" && $stick ne "3" && $stick ne "1" && $stick ne "b")
    {
      print "\tWARNING: Cannot parse sticky argument $stick - ignoring.\n";
      next;
    }
    $sticks{$stick}++;
  }
  $result = 0 if ($self->{onebpoverhang} && ! exists $sticks{1});
  my $type = $self->{type};
  $type =~ s/\'//xg;
  $result = 0 unless (exists $sticks{$type});
  return $result;
}

=head1 ACCESSOR METHODS

Methods for setting and accessing enzyme attributes

=head2 id

The name of the enzyme.

=cut

sub id
{
  my ($self) = @_;
  return $self->{id};
}

=head2 display_name

The name of the enzyme.

=cut

sub display_name
{
  my ($self) = @_;
  return $self->{id};
}

=head2 score

This attribute initially holds the price in dollars per unit of the enzyme
(2009 US Dollars) but can be used to hold any score or cost value.

=cut

sub score
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{score} = $value;
  }
  return $self->{score};
}

=head2 aggress

Aggressiveness is the number of recognition sites in a template piece of DNA
(usually lambda, but sometimes adeno2, pBR322, pUC19, pXba, etc) over the total
length of that template piece of DNA. This number tells the manufacturer how
much enzyme to sell as a "unit" - the amount of enzyme required to fully digest
one microgram of template DNA under reaction conditions in an hour.

=cut

sub aggress
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{aggress} = $value;
  }
  return $self->{aggress};
}

=head2 len

The length in bases of the recognition sequence (recseq).

=cut

sub len
{
  my ($self) = @_;
  return $self->{length};
}

=head2 methcpg

The effect of CpG methylation on the enzyme's efficacy.

=cut

sub methcpg
{
  my ($self) = @_;
  return $self->{methcpg};
}

=head2 methdcm

The effect of Dcm methylation on the enzyme's efficacy.

=cut

sub methdcm
{
  my ($self) = @_;
  return $self->{methdcm};
}

=head2 methdam

The effect of Dam methylation on the enzyme's efficacy.

=cut

sub methdam
{
  my ($self) = @_;
  return $self->{methdam};
}

=head2 buffers

A hash reference where the keys are buffer names and the values are the activity
level of the enzyme in that Buffer. Since most of the enzymes in the default
GeneDesign list are NEB enzymes, this is usually full of NEB buffers.

=cut

sub buffers
{
  my ($self) = @_;
  return $self->{buffers};
}

=head2 vendors

A hash reference where the keys are abbreviations for and the values are names
of vendors that stock the enzyme. These are read in from the enzyme file.

                      B = Invitrogen
                      C = Minotech
                      E = Stratagene
                      F = Thermo Scientific Fermentas
                      I = SibEnzyme
                      J = Nippon Gene Co.
                      K = Takara
                      M = Roche Applied Science
                      N = New England Biolabs
                      O = Toyobo Technologies
                      Q = Molecular Biology Resources
                      R = Promega
                      S = Sigma Aldrich
                      U = Bangalore Genei
                      V = Vivantis
                      X = EURx
                      Y = CinnaGen

=cut

sub vendors
{
  my ($self) = @_;
  return $self->{vendors};
}

=head2 tempin

The temperature in degrees Celsius that deactivates the enzyme.

=cut

sub tempin
{
  my ($self) = @_;
  return $self->{tempin};
}

=head2 timein

The time required at inactivation temperature to deactivate the enzyme.

=cut

sub timein
{
  my ($self) = @_;
  return $self->{timein};
}

=head2 temp

Incubation temperature for the best enzyme activity, in degrees Celsius.

=cut

sub temp
{
  my ($self) = @_;
  return $self->{temp};
}

=head2 recseq

This attribute is the "clean" description of the enzyme's recognition sequence -
that is, no information about cleavage site can be gained from this attribute.
This is determined automatically from the cleavage string (cutseq) at
instantiation.

=cut

sub recseq
{
  my ($self) = @_;
  return $self->{recseq};
}

=head2 seq

Synonym for recseq

=cut

sub seq
{
  my ($self) = @_;
  return $self->{recseq};
}

=head2 cutseq

This attribute is the string description of the enzyme's recognition sequence.
It includes information about both the recognition and cleavage sites.
See http://rebase.neb.com/rebase/rebrec.html for help interpreting this field.

=cut

sub cutseq
{
  my ($self) = @_;
  return $self->{cutseq};
}

=head2 regex

This attribute stores a set of regular expressions as an array reference to
speed the search for recognition sites in sequence. The first entry in the
arrayref is the regular expression representing the forward orientation of
the recognition sequence; the second entry represents the reverse orientation
and is only defined if the recognition site is nonpalindromic.

This attribute is defined at instantiation.

=cut

sub regex
{
  my ($self) = @_;
  return $self->{regex};
}

=head2 class

Class describes the cutting behavior of an enzyme. The classes used by
GeneDesign uses a generalized subset of the classes as described at Rebase - for
the purposes of enzyme editing, three classes have so far proven to be enough.
See http://rebase.neb.com/cgi-bin/sublist for the full description of enzyme
classes.

  IIP : This enzyme has a symmetric target and a symmetric cleavage site; this
        usually means that the enzyme cleaves inside its own recognition site.
        This is not the same as overhang palindromy!

  IIA : This enzyme has an asymmetric recognition site and usually cleaves
        outside of it.

  IIB : This enzyme has one recognition site and two cleavage sites, one on
        either side of the recognition site, and thus cuts itself out of
        sequence.

=cut

sub class
{
  my ($self) = @_;
  return $self->{class};
}

=head2 classex

=cut

sub classex
{
  my ($self) = @_;
  return $self->{classex};
}

=head2 class_regexes

Short cut to accessing class regular expressions

=cut

sub class_regexes
{
  return {'IIP' => $IIPreg, 'IIA' => $IIAreg, 'IIB' => $IIBreg};
}

=head2 type

Type describes the kind of overhang left by an enzyme. This is probably not a
good use of the word type.

Type may be 5', for a five prime overhang; 3', for a three prime overhang;
or b for blunt ends.

=cut

sub type
{
  my ($self) = @_;
  return $self->{type};
}


=head2 onebpoverhang

One basepair overhangs can be harder to ligate than blunt ends. This attribute
returns 1 if an enzyme leaves a 1bp overhang and 0 else.

=cut

sub onebpoverhang
{
  my ($self) = @_;
  return $self->{onebpoverhang};
}

=head2 exclude

Some enzymes share overlapping recognition sites. If you are trying to ensure
the absence or uniqueness of a recognition site, you will want to be sure to
exclude isoschizomers and neoschizomers from consideration elsewhere. The
exclude attribute stores an array reference that lists the ids of neo- and
isoschizomers - or any arbitrary enzyme that is incompatible with this enzyme -
for easy lookup.

=cut

sub exclude
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->throw("$value is not a reference to an array")
      unless (ref $value eq "ARRAY");
    $self->{exclude} = $value;
  }
  return $self->{exclude};
}

=head2 palindromy

Information about the overhang the enzyme leaves.

  pal     = palindromic
  nonpal  = nonpalindromic
  pnon    = potentially nonpalindromic, or sometimes palindromic and sometimes
            nonpalindromic
  unknown = unknown

=cut

sub palindromy
{
  my ($self) = @_;
  return $self->{palindromy};
}

=head2 staract

1 if the enzyme exhibits star activity, 0 else

=cut

sub staract
{
  my ($self) = @_;
  return $self->{staract};
}

=head2 start

The offset in nucleotides of the enzymes recognition site in an ORF

=cut

sub start
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{start} = $value;
  }
    return $self->{start};
}

=head2 outside_cut

=cut

sub outside_cut
{
  my ($self) = @_;
  return $self->{outside_cut};
}

=head2 inside_cut

=cut

sub inside_cut
{
  my ($self) = @_;
  return $self->{inside_cut};
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, GeneDesign developers
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
