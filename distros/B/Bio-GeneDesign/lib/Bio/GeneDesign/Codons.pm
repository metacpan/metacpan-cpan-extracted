#
# GeneDesign module for codon analysis and manipulation
#

=head1 NAME

GeneDesign::Codons

=head1 VERSION

Version 5.54

=head1 DESCRIPTION

GeneDesign functions for codon analysis and manipulation

=head1 AUTHOR

Sarah Richardson <SMRichardson@lbl.gov>.

=cut

package Bio::GeneDesign::Codons;
require Exporter;

use Bio::GeneDesign::Basic qw(:GD);
use Math::Combinatorics qw(combine);
use List::Util qw(max first);
use File::Basename;
use autodie qw(open close);
use Carp;

use strict;
use warnings;

our $VERSION = 5.54;

use base qw(Exporter);
our @EXPORT_OK = qw(
  _translate
  _reverse_codon_table
  _parse_organisms
  _parse_codon_file
  _subtract
  _codon_count
  _generate_RSCU_table
  _generate_codon_report
  _generate_codon_file
  _amb_translation
  _degcodon_to_aas
  _find_in_frame
  _minimize_local_alignment_dp
  _define_codons
  _pattern_aligner
  _pattern_adder
  _codon_change_type
  $VERSION
);
our %EXPORT_TAGS =  ( GD => \@EXPORT_OK );

my $CODLINE = qr/^ \{ ([ATCG]{3}) \} \s* = \s* (.+) $/x;
my %ambtransswits = map {$_ => 1} qw(1 2 3 -1 -2 -3 s t);

=head2 parse_organisms

=cut

sub _parse_organisms
{
  my ($path) = @_;
  my ($orgs, $cods) = ({}, {});
  opendir (my $CODDIR, $path) || croak "can't opendir $path";
  foreach my $table (readdir($CODDIR))
  {
    my $name = basename($table);
    $name =~ s{\.[^.]+$}{}x;
    if ($table =~ m{\.rscu\Z}x)
    {
      $orgs->{$name} = $path . $table;
    }
    elsif ($table =~ /\.ct\Z/x)
    {
      $cods->{$name} = $path . $table;
    }
  }
  closedir($CODDIR);
  return ($orgs, $cods);
}

=head2 parse_codon_file

=cut

sub _parse_codon_file
{
  my ($path) = @_;
  open (my $CFILE, '<', $path);
  my $ref = do { local $/ = <$CFILE> };
  close $CFILE;
  my @lines = split(/\n/x, $ref);
  my $cods = {};
  foreach my $line (grep {$_ !~ /^\#/x} @lines)
  {
    if ($line =~ $CODLINE)
    {
      $cods->{$1} = $2;
    }
    else
    {
      croak "Badly formatted definition in codon file $path: $line";
    }
  }
  my @codons = _define_codons();
  foreach my $codon (@codons)
  {
    croak "$path table is missing definition for codon $codon"
      unless (exists $cods->{$codon});
  }
  return $cods;
}

=head2 reverse_codon_table()

Takes a codon table hashref and reverses it such that each key is a one letter
amino acid residue and each value is an array reference containing all of the
codons that can code for that residue.

=cut

sub _reverse_codon_table
{
  my ($codontable) = @_;
  my $revcodon_t = {};
  foreach my $codon (sort {$a cmp $b} keys %$codontable)
  {
    my $aa = $codontable->{$codon};
    $revcodon_t->{$aa} = [] if ( ! exists $revcodon_t->{$aa} );
    push @{$revcodon_t->{$aa}}, $codon;
  }
  return $revcodon_t;
}

=head2 _translate()

takes a nucleotide sequence, a frame, and a codon table and returns that frame
translated into amino acids.

=cut

sub _translate
{
  my ($nucseq, $frame, $codon_t) = @_;
  $nucseq = _complement($nucseq, 1) if ($frame < 0);
  my $peptide = q{};
  my $limit = length $nucseq;
  my $offset = abs($frame) - 1;
  $limit-- while (($limit - $offset) % 3 != 0);
  while ($offset < $limit)
  {
    my $codon = substr $nucseq, $offset, 3;
    if (exists $codon_t->{$codon})
    {
      $peptide .= $codon_t->{$codon};
    }
    else
    {
      carp("GDWarning: $codon is untranslatable\n");
    }
    $offset += 3;
  }
  return $peptide;
}

=head2 _subtract

=cut

sub _subtract
{
  my ($oldseq, $pattern, $regarr, $codon_t, $rscu_t, $revcodon_t) = @_;
  my $seq = $oldseq;
  my $temphash = _positions($seq, $regarr);
  foreach my $gpos (sort keys %{$temphash})
  {
    my $framestart = $gpos % 3;
    my $startpos = int ( (length $temphash->{$gpos}) / 3 + 2 ) * 3;
    my $string = substr $seq, $gpos - $framestart, $startpos;
    my $newrepseg = $string;

    my %newseqs;
    my $len = (length $string) / 3;
    my $curval = _rscu_sum($rscu_t, $string);
    #compute the changes possible
    for my $it (1..$len)
    {
      my @map = map { join q{}, sort @{$_} } combine($it, (1..$len));
      foreach my $guide (@map)
      {
        my $rscuers = {};
        my @coords = sort split(q{}, $guide);
        $rscuers->{0} = [$string];
        my $passthrough = 0;
        foreach my $coord (@coords)
        {
          my $srcarr = $rscuers->{$passthrough};
          foreach my $str (@{$srcarr})
          {
            my $coda = substr $str, ($coord * 3) - 3, 3;
            foreach my $codb (grep {$coda ne $_}
                              @{$revcodon_t->{$codon_t->{$coda}}})
            {
              my $newstr = $str;
              substr $newstr, ($coord * 3) - 3, 3, $codb;
              push @{$rscuers->{$passthrough+1}}, $newstr;
            }
          }
          $passthrough++;
        }
        foreach my $newseq (@{$rscuers->{$passthrough}})
        {
          my $a = _rscu_sum($rscu_t, $newseq);
          my $b = _compare_sequences($string, $newseq);
          $newseqs{$newseq} = [sprintf("%.2f",abs($a - $curval)), $b->{D}];
        }
      }
    }
    #try all the changes
    foreach my $newseq (sort {$newseqs{$a}->[0] <=> $newseqs{$b}->[0]
                           || $newseqs{$a}->[1] <=> $newseqs{$b}->[1]}
                        keys %newseqs)
    {
      my $qeswen = _complement($newseq, 1);
      my $matchflag = 0;
      foreach my $regex (@{$regarr})
      {
        $matchflag++ if ($newseq =~ $regex);
        $matchflag++ if ($qeswen =~ $regex);
      }
      if ($matchflag == 0)
      {
        $newrepseg = $newseq;
        last;
      }
    }
    substr $seq, $gpos - $framestart, (length $newrepseg), $newrepseg;
  }
  return $seq;
}

=head2 _rscu_sum()

=cut

sub _rscu_sum
{
  my ($rscu_t, $ntseq) = @_;
  my $offset = 0;
  my $rscusum = 0;
  my $length = length $ntseq;
  my $rem = $length % 3;
  while ($offset < ($length - $rem))
  {
    my $cod = substr $ntseq, $offset, 3;
    $rscusum += $rscu_t->{$cod};
    $offset += 3;
  }
  return $rscusum;
}

=head2 _codon_count()

takes a reference to an array of sequences and returns a hash with codons as
keys and the number of times the codon occurs as a value.

=cut

sub _codon_count
{
  my ($seqs, $codon_t, $hashref) = @_;
  my %blank = map {$_ => 0} sort keys %$codon_t;
  my $codoncount = $hashref || \%blank;
  foreach my $seq (@$seqs)
  {
    my @arr = ($seq =~ m/ [ATCG]{3} /xg);
    foreach my $codon (@arr)
    {
      $codoncount->{$codon}++;
    }
  }
  return $codoncount;
}

=head2 generate_RSCU_table()

takes a hash reference with keys as codons and values as number of times
those codons occur (it helps to use codon_count) and returns a hash with each
codon and its RSCU value

=cut

sub _generate_RSCU_table
{
  my ($codon_count, $codon_t, $revcodon_t) = @_;
  my $RSCU_hash = {};
  foreach my $codon (sort grep {$_ ne "XXX"} keys %$codon_count)
  {
    my $x_j = 0;
    my $x = $codon_count->{$codon};
    my $family = $revcodon_t->{$codon_t->{$codon}};
    my $family_size = scalar(@$family);
    foreach (grep {exists $codon_count->{$_}} @$family)
    {
      $x_j += $codon_count->{$_};
    }
    my $rscu = $x_j > 0 ? $x / ($x_j / $family_size) : 0.00;
    $RSCU_hash->{$codon} = sprintf("%.2f",  $rscu ) ;
  }
  return $RSCU_hash;
}

=head2 _generate_codon_report

=cut

sub _generate_codon_report
{
  my ($codon_count, $codon_t, $rscu_t) = @_;
  my $string = "Codon counts and RSCU values:\n";
  my @codvalsort = sort {$b <=> $a} values %{$codon_count};
  my $maxcodnum = $codvalsort[0];
  foreach my $a ( qw(T C A G))
  {
    $string .= "\n";
    foreach my $c ( qw(T C A G) )
    {
      foreach my $b ( qw(T C A G) )
      {
        my $codon = $a . $b . $c;
        my $count = $codon_count->{$codon};
        my $spacer = q{ } x (length($maxcodnum) - length($count));
        $string .=  "$codon (" . $codon_t->{$codon} . ") $spacer$count ";
        $string .=  $rscu_t->{$codon} . q{ } x 5;
      }
      $string .= "\n";
    }
    $string .= "\n";
  }
  return $string;
}

=head2 _generate_codon_file

=cut

sub _generate_codon_file
{
  my ($table, $rev_cod_t, $comments) = @_;
  my $string = q{};
  my @cs = @$comments;
  $string .= "# " . $_  . "\n" foreach (@cs);
  foreach my $aa (sort keys %$rev_cod_t)
  {
    my @codons = @{$rev_cod_t->{$aa}};
    $string .= "#$aa\n";
    foreach my $codon (sort @codons)
    {
      $string .= "{$codon} = $table->{$codon}\n";
    }
  }
  return $string;
}

=head2 _define_codons

Generates an array reference that contains every possible nucleotide codon

=cut

sub _define_codons
{
  my @codons;
  foreach my $a (qw(A T C G))
  {
    foreach my $b (qw(A T C G))
    {
      foreach my $c (qw(A T C G))
      {
        push @codons, $a . $b . $c;
      }
    }
  }
  return @codons;
}

=head2 _amb_translation()

takes a nucleotide that may be degenerate and a codon table and returns a list
of all amino acid sequences that nucleotide sequence could be translated into.

  in: nucleotide sequence (string),
      codon table (hash reference),
      optional switch to force only a single frame of translation
      optional hashref of previous answers to speed processing
  out: amino acid sequence list (vector)

=cut

sub _amb_translation
{
  my ($seq, $codon_t, $swit, $memo) = @_;
  croak ("Bad frame argument\n") unless exists $ambtransswits{$swit};
  if ($swit eq "s" || $swit eq "t")
  {
    my @frames = qw(1 2 3);
    push @frames, qw(-1 -2 -3) if ($swit eq "s");
    my (%RES);
    foreach my $s (@frames)
    {
      my @pep_set = _amb_translation($seq, $codon_t, $s, $memo);
      $RES{$_}++ foreach (@pep_set);
    }
    return keys %RES;
  }
  else
  {
    my (%RES, @SEED, @NEW);
    $seq = _complement($seq, 1) if ($swit < 0);
    $seq = 'N' x (abs($swit) - 1) . $seq if (abs($swit) < 4);
    my $seqlen = length($seq);
    my $gothrough = 0;
    for (my $offset = 0; $offset < $seqlen; $offset += 3)
    {
      my $tempcodon = substr($seq, $offset, 3);
      $tempcodon .= "N" while (length($tempcodon) % 3);
      if (!$swit)
      {
        $tempcodon .= 'N' while (length($tempcodon) < 3);
      }
      if ($gothrough == 0)
      {
        @SEED = _degcodon_to_aas($tempcodon, $codon_t, $memo) ;
      }
      else
      {
        @NEW  = _degcodon_to_aas($tempcodon, $codon_t, $memo);
        @SEED = _add_arr(\@SEED, \@NEW);
      }
      $gothrough++;
    }
    $RES{$_}++ foreach(@SEED);
    return keys %RES;
  }
}

=head2 _degcodon_to_aas()

takes a codon that may be degenerate and a codon table and returns a list of
all amino acids that codon could represent. If a hashref is provided with
previous answers, it will run MUCH faster (memoization).

  in: codon (string),
      codon table (hash reference)
  out: amino acid list (vector)

=cut

sub _degcodon_to_aas
{
  my ($codon, $codon_t, $memo) = @_;
  return if ( ! $codon  ||  length($codon) != 3);
  my (@answer, %temphash) = ((), ());
  if (exists $memo->{$codon})
  {
    return @{$memo->{$codon}};
  }
  elsif ($codon eq "NNN")
  {
    %temphash = map { $_ => 1} values %$codon_t;
    @answer = keys %temphash;
  }
  else
  {
    my $reg = _regres($codon, 1);
    %temphash = map {$codon_t->{$_}  => 1} grep { $_ =~ $reg } keys %$codon_t;
    @answer = keys %temphash;
  }
  $memo->{$codon} = \@answer;
  return @answer;
}

=head2 _find_in_frame

=cut

sub _find_in_frame
{
  my ($ntseq, $pattern, $codon_t) = @_;
  my $regex = _regres($pattern, 2);
  my $aaseq = _translate($ntseq, 1, $codon_t);
  my $hshref = _positions($aaseq, [$regex]);
  my $pattntlen = length($pattern) * 3;
  my $answer = {};
  foreach my $ao (keys %$hshref)
  {
    my $nuco = 3 * $ao;
    $answer->{$nuco} = substr($ntseq, $nuco, $pattntlen);
  }
  return $answer;
}

=head2 _minimize_local_alignment_dp()

Repeatsmasher, by Dongwon Lee. A function that minimizes local alignment
scores.

  in: gene sequence (string)
      codon table (hashref)
      RSCU table (hashref)
  out: new gene sequence (string)
  #NO UNIT TEST

=cut

sub _minimize_local_alignment_dp
{
  my ($oldseq, $codon_t, $rev_codon_t, $rscu_t) = @_;
  my $match = 5;
  my $transi = -3;
  my $transv = -4;
  my $score_threshold = $match*6; #count the scores only consecutive 6 nts
  my @s = ( [$match, $transv, $transi, $transv],
            [$transv, $match, $transv, $transi],
            [$transi, $transv, $match, $transv],
            [$transv, $transi, $transv, $match] );
  my %nt2idx = ("A"=>0, "C"=>1, "G"=>2, "T"=>3);

  #initial values
  my @optM = (0);
  my $optseq = q{};

  #assumming that the sequence is in frame
  my ($offset, $cod, $aa) = (0, q{}, q{});
  my $oldlen = length($oldseq) - 3;
  while ( $offset <= $oldlen )
  {
    $cod = substr($oldseq, $offset, 3);
    $aa  = _translate($cod, 1, $codon_t);
    my @posarr = sort { $rscu_t->{$b} <=> $rscu_t->{$a} }
                  @{$rev_codon_t->{$aa}};

    my @minM = ();
    my $min_seq = q{};
    #assign an impossible large score
    my $min_score = $match*(length($oldseq)**2);

    if ($aa ne '*')
    {
      foreach my $newcod (@posarr)
      {
        my @prevM = @optM;
        my $prevseq = $optseq;

        foreach my $nt (split(//, $newcod))
        {
          my $currseq = $prevseq . $nt;
          my $currlen = length($currseq);
          my @currM = ();
          my $pos = 0;
          push @currM, 0;
          while($pos < $currlen)
          {
            my $nt2 = substr($currseq, $pos, 1);
            my $nidx1 = $nt2idx{$nt};
            my $nidx2 = $nt2idx{$nt2};
            push @currM, max(0, $prevM[$pos]+$s[$nidx1][$nidx2]);
            $pos++;
          }
          @prevM = @currM;
          $prevseq = $currseq;
        }
        my $scoresum = 0;
        foreach my $i (@prevM)
        {
          if ($i >= $score_threshold)
          {
            $scoresum += $i;
          }
        }
        if ($min_score > $scoresum)
        {
          $min_score = $scoresum;
          $min_seq = $prevseq;
          @minM = @prevM;
        }
      }
    }
    else
    {
      $optseq = $optseq . $cod;
      last;
    }
    @optM = @minM;
    $optseq = $min_seq;
    $offset+=3;
  }
  return $optseq;
}

=head2 _pattern_aligner

takes a nucleotide sequence, a pattern, a peptide sequence, and a codon table
and inserts Ns before the pattern until they align properly. This is so a
pattern can be inserted out of frame.

  in: nucleotide sequence (string),
      nucleotide pattern (string),
      amino acid sequence (string),
      codon table (hash reference)
  out: nucleotide pattern (string)

=cut

sub _pattern_aligner
{
  my ($critseg, $pattern, $peptide, $codon_t, $memo) = @_;
  my $diff = length($critseg) - length($pattern);
  my ($newpatt, $nstring, $rounds, $offset, $check, $pcheck) = (q{}, "N" x $diff, 0, 0, q{}, q{});
  #  print "seeking $pattern for $peptide from $critseg...\n";
  while ($check ne $peptide && $rounds <= $diff*2 + 1)
  {
    $newpatt = $rounds <= $diff
      ?  substr($nstring, 0, $rounds) . $pattern
      :  substr($nstring, 0, ($rounds-3)) . _complement($pattern, 1);
    $newpatt .=  "N" while (length($newpatt) != length($critseg));
    #  print "\t$newpatt\n";
    my ($noff, $poff) = (0, 0);
    $check = q{};
    while ($poff < length($peptide))
    {
      my @possibles = _degcodon_to_aas( substr($newpatt, $noff, 3), $codon_t, $memo );
      #   print "\t\t@possibles\n";
      $check .= $_ foreach( grep { substr($peptide, $poff, 1) eq $_ } @possibles);
      $noff += 3;
      $poff ++;
    }
    $pcheck = _translate(substr($critseg, $offset, length($peptide) * 3), 1, $codon_t);
    #      print "\t\t$check, $pcheck, $offset\n";
    $rounds++;
    $offset += 3 if ($rounds % 3 == 0);
#    $check = q{} if ( $pcheck !~ $check);
  }
  $newpatt = "0" if ($check ne $peptide);
  # print "\t\tpataln $check, $pcheck, $rounds, $newpatt\n" if ($check ne $peptide);
  return ($newpatt, $rounds - 1);
}

=head2 _pattern_adder()

takes a nucleotide sequence, a nucleotide "pattern" to be interpolated, and
the codon table, and returns an edited nucleotide sequence that contains the
pattern (if possible).

  in: nucleotide sequence (string),
      nucleotide pattern (string),
      codon table (hash reference)
  out: nucleotide sequence (string) OR null

=cut

sub _pattern_adder
{
  my ($oldpatt, $newpatt, $codon_t, $revcodon_t, $memo) = @_;
  #assume that critseg and pattern come in as complete codons
  # (i.e., have been run through pattern_aligner)
  my $copy = q{};
  for (my $offset = 0; $offset < length($oldpatt); $offset += 3)
  {
    my $curcod = substr($oldpatt, $offset, 3);
    my $curtar = substr($newpatt, $offset, 3);
    my $ctregx = _regres($curtar);
    foreach my $g (_degcodon_to_aas($curcod, $codon_t, $memo))
    {
      if ($curcod =~ $ctregx)
      {
        $copy .= $curcod;
      }
      else
      {
        my @arr = @{$revcodon_t->{$g}};
        foreach my $potcod (@arr)
        {
          my $flag = 0;
          $flag++ if ($potcod =~ $ctregx || $curtar =~ _regres($potcod));
          if ($flag != 0)
          {
            $copy .= $potcod;
            last;
          }
        }
      }
      # print "\t\tpatadd\t($curcod, $curtar)\t$copy<br>\n";
    }
  }
  # print "\t\tpatadd $copy from $oldpatt\n";
  return length($copy) == length($oldpatt)  ?  $copy  :  0;
}

=head2 _codon_change_type

=cut

sub _codon_change_type
{
	my ($oldcod, $newcod, $codon_t) = @_;
  my $oldaa = $codon_t->{$oldcod};
  my $newaa = $codon_t->{$newcod};
	my $type = $oldaa eq $newaa
			          ?	$oldaa eq q{*}
					        ?	'stop_retained_variant'
					        :	'synonymous_codon'
						    :	$oldaa eq q{*}
					        ?	'stop_lost'
							    :	$newaa eq q{*}
							      ?	'stop_gained'
							      :	'non_synonymous_codon';
	return $type;
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
