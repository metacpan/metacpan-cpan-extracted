#
# Basic GeneDesign libraries
#

=head1 NAME

Bio::GeneDesign::Basic

=head1 VERSION

Version 5.56

=head1 DESCRIPTION

GeneDesign is a library for the computer-assisted design of synthetic genes

=head1 AUTHOR

Sarah Richardson <SMRichardson@lbl.gov>

=cut

package Bio::GeneDesign::Basic;
require Exporter;

use POSIX qw(log10);
use Carp;

use strict;
use warnings;

our $VERSION = 5.56;

use base qw(Exporter);
our @EXPORT_OK = qw(
  _generate_dimers
  _sanitize
  _count
  _gcwindows
  _ntherm
  _complement
  _toRNA
  _melt
  _regres
  _regarr
  _positions
  _find_runs
  _is_ambiguous
  _compare_sequences
  _amb_transcription
  _add_arr
  $ambnt
  @BASES
  %NTIDES
  %AA_NAMES
  %AACIDS
);

our %EXPORT_TAGS =  (GD=> \@EXPORT_OK);

=head1 Definitions

=cut

our @BASES = qw(A T C G);

our %NTIDES = (
  A => [qw(A)],     T => [qw(T)],
  C => [qw(C)],     G => [qw(G)],
  R => [qw(A G)],   Y => [qw(C T)],
  W => [qw(A T)],   S => [qw(C G)],
  K => [qw(G T)],   M => [qw(A C)],
  B => [qw(C G T)], D => [qw(A G T)],
  H => [qw(A C T)], V => [qw(A C G)],
  N => [qw(A C G T)],
);

my %REGHSH = (
  A => 'A',         T => 'T',
  C => 'C',         G => 'G',
  R => '[AGR]',     Y => '[CTY]',
  W => '[ATW]',     S => '[CGS]',
  K => '[GKT]',     M => '[ACM]',
  B => '[BCGKSTY]', D => '[ADGKRTW]',
  H => '[ACHMTWY]', V => '[ACGMRSV]',
  N => '[ABCDGHKMNRSTVWY]',
);

our $ambnt    = qr/[R Y W S K M B D H V N]+/x;

our %AACIDS = map { $_ => $_ } qw(A C D E F G H I K L M N P Q R S T V W Y);
$AACIDS{"*"} = "[\*]";

our %AA_NAMES = (
  A => 'Ala', B => 'Unk', C => 'Cys', D => 'Asp', E => 'Glu', F => 'Phe',
  G => 'Gly', H => 'His', I => 'Ile', J => 'Unk', K => 'Lys', L => 'Leu',
  M => 'Met', N => 'Asn', O => 'Unk', P => 'Pro', Q => 'Gln', R => 'Arg',
  S => 'Ser', T => 'Thr', U => 'Unk', V => 'Val', W => 'Trp', X => 'Unk',
  Y => 'Tyr', Z => 'Unk', '*' => 'Stp');

# entropy, enthalpy, and free energy of paired bases
my %EEG = (
  "TC" => ([ 8.8, 23.5, 1.5]), "GA" => ([ 8.8, 23.5, 1.5]),
  "CT" => ([ 6.6, 16.4, 1.5]), "AG" => ([ 6.6, 16.4, 1.5]),
  "GG" => ([10.9, 28.4, 2.1]), "CC" => ([10.9, 28.4, 2.1]),
  "AA" => ([ 8.0, 21.9, 1.2]), "TT" => ([ 8.0, 21.9, 1.2]),
  "AT" => ([ 5.6, 15.2, 0.9]), "TA" => ([ 6.6, 18.4, 0.9]),
  "CG" => ([11.8, 29.0, 2.8]), "GC" => ([10.5, 26.4, 2.3]),
  "CA" => ([ 8.2, 21.0, 1.7]), "TG" => ([ 8.2, 21.0, 1.7]),
  "GT" => ([ 9.4, 25.5, 1.5]), "AC" => ([ 9.4, 25.5, 1.5])
);

=head1 Functions

=head2 _generate_dimers

=cut

sub _generate_dimers
{
  my @dimers;
  foreach my $a (@BASES)
  {
    foreach my $b (@BASES)
    {
      push @dimers, $a . $b;
    }
  }
  return @dimers;
}

=head2 _sanitize()

remove non nucleotide characters from nucleotide sequences. remove non amino
acid characters from peptide sequences. return sanitized strand and list of bad
characters.

=cut

sub _sanitize
{
  my ($strand, $swit) = @_;
  $swit = $swit || 'nuc';
  die ('bad sanitize switch') if ($swit ne 'nuc' && $swit ne 'pep');
  my %noncount = ();
  my $newstrand = q{};
  my @arr = split q{}, $strand;
  foreach my $char (@arr)
  {
    my $CH = uc $char;
    if ($swit eq 'nuc' && exists $NTIDES{$CH}
    || ($swit eq 'pep' && exists $AACIDS{$CH}))
    {
      $newstrand .= $char;
    }
    else
    {
      $noncount{$char}++;
    }
  }
  my @baddies = keys %noncount;
  return ($newstrand, @baddies);
}

=head2 _count()

takes a nucleotide sequence and returns a base count.  Looks for total length,
purines, pyrimidines, and degenerate bases. If degenerate bases are present
assumes their substitution for non degenerate bases is totally random for
percentage estimation.

  in: nucleotide sequence (string),
  out: base count (hash)

=cut

sub _count
{
  my ($strand) = @_;
  my $len = length $strand;
  my @arr = split q{}, uc $strand;
  my %C = map {$_ => 0} keys %NTIDES;

  #Count bases
  $C{$_}++ foreach @arr;

  $C{d} += $C{$_} foreach (qw(A T C G));
  $C{n} += $C{$_} foreach (qw(B D H K M N R S V W Y));
  $C{'?'} = ($C{d} + $C{n}) - $len;

  #Estimate how many of each degenerate base would be a G or C
  my $split = .5*$C{R}  + .5*$C{Y}  + .5*$C{K}  + .5*$C{M}  + .5*$C{N};
  my $trip  = (2*$C{B} / 3) + (2*$C{V} / 3) + ($C{D} / 3) + ($C{H} / 3);

  #Calculate GC/AT percentage
  my $gcc = $C{S} + $C{G} + $C{C} + $split + $trip;
  my $gcp = sprintf "%.1f", ($gcc / $len) * 100;
  $C{GCp} = $gcp;
  $C{ATp} = 100 - $gcp;
  $C{len} = $len;

  return \%C;
}

=head2 _gcwindows()

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

sub _gcwindows
{
  my ($seq, $winsize, $min, $max) = @_;
  my @minflags = ();
  my @maxflags = ();
  my $seqlen = length $seq;
  my $lefpos = 0;
  my $rigpos = $winsize - 1;
  my $win = substr $seq, $lefpos, $winsize;
  my %hsh = (G => 0, C => 0, A => 0, T => 0);
  $hsh{$_}++ foreach (split q{}, $win);
  my $initbase = substr $seq, $lefpos, 1;
  my $lastbase = substr $seq, $rigpos, 1;
  while ($rigpos < $seqlen)
  {
    my $GCperc = 100 * (($hsh{G} + $hsh{C}) / $winsize);
    $lefpos++;
    $rigpos++;
    if ($GCperc < $min)
    {
      push @minflags, [$lefpos, $rigpos];
    }
    if ($GCperc > $max)
    {
      push @maxflags, [$lefpos, $rigpos];
    }
    $hsh{$initbase}--;
    $initbase = substr $seq, $lefpos, 1;
    $lastbase = substr $seq, $rigpos, 1;
    $hsh{$lastbase}++;
  }
  
  return [\@minflags, \@maxflags];
}

=head2 _melt()

takes a nucleotide sequence and returns a melting temperature

  in: nucleotide sequence (string)
      salt concentration (string, opt, def =.05),
      oligo concentration (string, opt, def = .0000001)
  out: temperature (float)

=cut

sub _melt
{
  my ($strand, $salt, $conc) = @_;
  my $C = _count($strand);
  my $len = length($strand);
  $salt = $salt || .05;
  $conc = $conc || .0000001;
  my $Naj = 16.6 * log10($salt);

  my $Tm;

  if ($len < 14)
  {
    $Tm = ((4 * ($C->{C} + $C->{G})) + (2 * ($C->{A} + $C->{T})));
  }
  elsif ($len >= 14 && $len <= 50)
  {
    $Tm = 100.5 + (41 * ($C->{G} + $C->{C}) / $len) - (820/$len) + $Naj;
  }
  elsif ($len > 50)
  {
    $Tm = 81.5 + (41 * ($C->{G} + $C->{C}) / $len) - (500/$len) + $Naj - .62;
  }
  return sprintf "%.1f", $Tm;
}

=head2 _ntherm()

takes a nucleotide sequence and returns a nearest neighbor melting temp.

  in: nucleotide sequence (string)
  out: temperature (float)

=cut

sub _ntherm
{
  my ($strand, $salt, $conc) = @_;
  my ($dH, $dS, $dG) = (0, 0, 0);
  foreach my $w (keys %EEG)
  {
    while ($strand =~ /(?=$w)/ixg)
    {
      $dH += $EEG{$w}->[0];
      $dS += $EEG{$w}->[1];
      #$dG += $EEG{$w}->[2];
    }
  }
  $salt = $salt || .05;
  $conc = $conc || .0000001;
  my $Naj = 16.6 * log10($salt);
  my $lc = 1.987 * abs( log( $conc / 2 ) );
  my $Tm =  ( ( ($dH - 3.4) / ( ($dS + $lc) / 1000) ) - 273.15) + $Naj;
  return sprintf "%.1f", $Tm;
}

=head2 _complement()

takes a nucleotide sequence and returns its complement or reverse complement.

  in: nucleotide sequence (string),
      switch for reverse complement (1 or null)
  out: nucleotide sequence (string)

=cut

sub _complement
{
  my ($strand, $swit) = @_;
  $strand = scalar reverse($strand) if ($swit);
  $strand =~ tr/AaCcGgTtRrYyKkMmBbDdHhVv/TtGgCcAaYyRrMmKkVvHhDdBb/;
  return $strand;
}

=head2 _toRNA()

=cut

sub _toRNA
{
  my ($strand) = @_;
  $strand =~ tr/Tt/Uu/;
  return $strand;
}

=head2 _regres()

takes a  sequence that may be degenerate and returns a string that is prepped
for use in a regular expression.

  in: sequence (string),
      switch for aa or nt sequence (1 or null)
  out: regexp string (string)

=cut

sub _regres
{
  my ($sequence, $swit) = @_;
  $swit = $swit || 1;
  my $comp = q{};
  my @arr = split('', uc $sequence);
  foreach my $char (@arr)
  {
    if ($swit == 1)
    {
      my $ntide = $REGHSH{$char};
      croak ("$char is not a nucleotide\n") unless $ntide;
      $comp .= $ntide;
    }
    elsif ($swit == 2)
    {
      my $aa = $AACIDS{$char};
      croak ("$char is not an amino acid \n") unless $aa;
      $comp .= $aa;
    }
  }
  return qr/$comp/ix;
}

=head2 regarr()

=cut

sub _regarr
{
  my ($sequence) = @_;
  my $regex = [_regres($sequence, 1)];
  my $comp = _complement($sequence, 1);
  if ($comp ne $sequence)
  {
    push @$regex, _regres($comp, 1);
  }
  return $regex;
}

=head2 _positions()

=cut

sub _positions
{
  my ($seq, $regarr) = @_;
  my $temphash = {};
  foreach my $sit (@$regarr)
  {
    while ($seq =~ /(?=($sit))/ixg)
    {
      $temphash->{pos $seq} = $1;
    }
  }
  return $temphash;
}

=head2 _find_runs

=cut

sub _find_runs
{
  my ($seq, $pattern, $min) = @_;
  my @arr = ();
  $min = $min || 5;
  if (_is_ambiguous($pattern))
  {
    die "Ambiguous pattern passed to _find_runs";
  }
  my $reg = '[' . $pattern . ']';
  while ($seq =~ m{(($pattern) {$min,})}msixg)
  {
    my $len = length $1;
    my $rig = pos $seq;
    my $lef = $rig - $len + 1;
    push @arr, [$lef, $rig];
  }
  return \@arr;
}

=head2 _is_ambiguous

=cut

sub _is_ambiguous
{
  my ($sequence) = @_;
  return 1 if ($sequence =~ $ambnt);
  return 0;
}

=head2 _compare_sequences()

takes two nucleotide sequences that are assumed to be perfectly aligned and
roughly equivalent and returns similarity metrics. should be twweeaakkeedd

  in: 2x nucleotide sequence (string)
  out: similarity metrics (hash)

=cut

sub _compare_sequences
{
  my ($topseq, $botseq) = @_;
  return if (!$botseq || length($botseq) != length($topseq));
  my ($tsit, $tver, $len) = (0, 0, length($topseq));
  while (length($topseq) > 0)
  {
    my ($topbit, $botbit) = (chop($topseq), chop ($botseq));
    if ($topbit ne $botbit)
    {
      $topbit = $topbit =~ $REGHSH{R}  ?  1  :  0;
      $botbit = $botbit =~ $REGHSH{R}  ?  1  :  0;
      $tsit++ if ($topbit == $botbit);
      $tver++ if ($topbit != $botbit);
    }
  }
  my %A;
  $A{D} = $tsit + $tver;               #changes
  $A{I} = $len - $A{D};                #identities
  $A{T} = $tsit;                       #transitions
  $A{V} = $tver;                       #transversions
  $A{P} = sprintf "%.1f", 100 - (($A{D} / $len) * 100);  #percent identity
  return \%A;
}

=head2 _amb_transcription

=cut

sub _amb_transcription
{
  my ($ntseq) = @_;
  my $prseq = uc $ntseq;
  my (@SEED, @NEW) = ((), ());
  my $offset = 0;
  my $ntlen = length $prseq;
  while ($offset < $ntlen)
  {
    my $template = substr $prseq, $offset, 1;
    my $ntides = $NTIDES{$template};
    my $possibilities = scalar @$ntides;
    if ($possibilities == 1)
    {
      @SEED = ( $template ) if ($offset == 0);
      @NEW  = ( $template ) if ($offset >  0);
    }
    else
    {
      @SEED = @$ntides if ($offset == 0);
      @NEW  = @$ntides if ($offset >  0);
    }
    unless ($offset == 0)
    {
      @SEED = _add_arr(\@SEED, \@NEW);
    }
    $offset ++;
  }
  my %hsh = map {$_ => 1 } @SEED;
  my @keys = sort keys %hsh;
  return \@keys;
}


=head2 _add_arr

Basically builds a list of tree nodes for the amb_trans* functions.
in: 2 x peptide lists (array reference) out: combined list of peptides

=cut

sub _add_arr
{
  my ($arr1ref, $arr2ref) = @_;
  my @arr1 = @$arr1ref;
  my @arr2 = @$arr2ref;
  my @arr3 = ();
  foreach my $do (@arr1)
  {
    foreach my $re (@arr2)
    {
      push @arr3, $do . $re
    }
  }
  return @arr3;
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
