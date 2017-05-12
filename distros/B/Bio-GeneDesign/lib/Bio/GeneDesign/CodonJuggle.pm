=head1 NAME

Bio::GeneDesign::CodonJuggle

=head1 VERSION

Version 5.54

=head1 DESCRIPTION

Codon Juggle a sequence using rscu data to determine replacement likelihood

=head1 AUTHOR

Sarah Richardson <SMRichardson@lbl.gov>.

=cut

package Bio::GeneDesign::CodonJuggle;
require Exporter;

use Bio::GeneDesign::Random qw(_random_index _weighted_rand);
use Bio::GeneDesign::Basic qw(_compare_sequences);
use Carp;

use strict;
use warnings;

our $VERSION = 5.54;

use base qw(Exporter);
our @EXPORT_OK = qw(
  _list_algorithms
  _codonJuggle_balanced
  _codonJuggle_high
  _codonJuggle_least_different_rscu
  _codonJuggle_most_different_sequence
  _codonJuggle_random
);
our %EXPORT_TAGS =  (GD => \@EXPORT_OK);

=head2 _list_algorithms

=cut

sub _list_algorithms
{
  my %hsh =
  (
    balanced                => 'weighted averages',
    high                    => 'uniformly most used',
    least_different_RSCU    => 'least different by RSCU value',
    most_different_sequence => 'most different by sequence identity',
    random                  => 'random',
  );
  return \%hsh;
}

=head2 _codonJuggle_balanced

=cut

sub _codonJuggle_balanced
{
  my ($codon_table, $reverse_codon_table, $rscu_table, $nucseq) = @_;
  $nucseq = uc $nucseq;
  my %changehsh = ();
  foreach my $aa (keys %$reverse_codon_table)
  {
    $changehsh{$aa} = {};
    my @codons = @{$reverse_codon_table->{$aa}};
    my $count = scalar(@codons);
    my $checksum = 0;
    foreach my $coda (@codons)
    {
      my $likely = ($rscu_table->{$coda}) / $count;
      $changehsh{$aa}->{$coda} = $likely;
      $checksum += $likely;
    }
    if ($checksum == 0)
    {
      croak "This RSCU table has no positive values for $aa\n";
    }
  }
  my $offset = 0;
  my $newseq = q{};
  while ($offset < length($nucseq))
  {
    my $curcod = substr($nucseq, $offset, 3);
    my $aa = $codon_table->{$curcod};
    my $newcod = _weighted_rand($changehsh{$aa});
    $newseq .= $newcod;
    $offset += 3;
  }
  return $newseq;
}

=head2 _codonJuggle_high


=cut

sub _codonJuggle_high
{
  my ($codon_table, $reverse_codon_table, $rscu_table, $nucseq) = @_;
  my $cod_highs = {};
  foreach my $aa (keys %{$reverse_codon_table})
  {
    my $myrscu = -1;
    foreach my $codon (@{$reverse_codon_table->{$aa}})
    {
      if ($rscu_table->{$codon} > $myrscu)
      {
        $cod_highs->{$aa} = $codon;
        $myrscu = $rscu_table->{$codon};
      }
    }
  }
  my $offset = 0;
  my $newseq = q{};
  while ($offset < length($nucseq))
  {
    my $curcod = substr($nucseq, $offset, 3);
    $newseq .= $cod_highs->{$codon_table->{$curcod}};
    $offset += 3;
  }
  return $newseq;
}

=head2 _codonJuggle_least_different_rscu

=cut

sub _codonJuggle_least_different_rscu
{
  my ($codon_table, $reverse_codon_table, $rscu_table, $nucseq) = @_;
  my %changehsh = ();
  foreach my $aa (sort keys %$reverse_codon_table)
  {
    foreach my $coda (@{$reverse_codon_table->{$aa}})
    {
      $changehsh{$coda} = $coda;
      my @posarr = sort {abs($rscu_table->{$a} - $rscu_table->{$coda})
                     <=> abs($rscu_table->{$b} - $rscu_table->{$coda})}
                   grep {abs($rscu_table->{$_} - $rscu_table->{$coda}) <= 1}
                   grep {$_ ne $coda}
                   @{$reverse_codon_table->{$aa}};
      $changehsh{$coda} = $posarr[0] if (scalar @posarr);
    }
  }

  my $offset = 0;
  my $newseq = q{};
  while ($offset < length($nucseq))
  {
    my $curcod = substr($nucseq, $offset, 3);
    $newseq .= $changehsh{$curcod};
    $offset += 3;
  }
  return $newseq;
}

=head2 _codonJuggle_most_different_sequence

=cut

sub _codonJuggle_most_different_sequence
{
  my ($codon_table, $reverse_codon_table, $rscu_table, $nucseq) = @_;
  my %changehsh = ();
  foreach my $aa (sort keys %$reverse_codon_table)
  {
    foreach my $coda (@{$reverse_codon_table->{$aa}})
    {
      my %hsh;
      foreach my $codb (@{$reverse_codon_table->{$aa}})
      {
        $hsh{$codb} = _compare_sequences($coda, $codb);
      }
      my @mdcod = sort {$hsh{$b}->{D} <=> $hsh{$a}->{D}
                    ||  $hsh{$b}->{V} <=> $hsh{$a}->{V}
                    ||    abs($rscu_table->{$a} - $rscu_table->{$coda})
                      <=> abs($rscu_table->{$b} - $rscu_table->{$coda})}
                  keys %hsh;
      if (scalar @mdcod > 1)
      {
       shift @mdcod if ($mdcod[0] eq $coda);
      }
      $changehsh{$coda} = $mdcod[0];
    }
  }

  my $offset = 0;
  my $newseq = q{};
  while ($offset < length($nucseq))
  {
    my $curcod = substr($nucseq, $offset, 3);
    $newseq .= $changehsh{$curcod};
    $offset += 3;
  }
  return $newseq;
}


=head2 _codonJuggle_random

=cut

sub _codonJuggle_random
{
  my ($codon_table, $reverse_codon_table, $rscu_table, $nucseq) = @_;
  my $cod_highs = {};
  foreach my $aa (keys %{$reverse_codon_table})
  {
    $cod_highs->{$aa} = [];
    foreach my $codon (@{$reverse_codon_table->{$aa}})
    {
        push @{$cod_highs->{$aa}}, $codon;
    }
  }
  my $offset = 0;
  my $newseq = q{};
  while ($offset < length($nucseq))
  {
    my $curcod = substr($nucseq, $offset, 3);
    my $aa = $codon_table->{$curcod};
    my $index = _random_index(scalar @{$cod_highs->{$aa}});
    $newseq .= $cod_highs->{$aa}->[$index];
    $offset += 3;
  }
  return $newseq;
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
