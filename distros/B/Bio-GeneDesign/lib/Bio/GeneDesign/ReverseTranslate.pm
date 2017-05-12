=head1 NAME

Bio::GeneDesign::ReverseTranslate

=head1 VERSION

Version 5.54

=head1 DESCRIPTION

Reverse translate a sequence using rscu values to set replacement likelihood

=head1 AUTHOR

Sarah Richardson <SMRichardson@lbl.gov>.

=cut

package Bio::GeneDesign::ReverseTranslate;
require Exporter;

use Bio::GeneDesign::Random qw(_random_index _weighted_rand);
use Carp;

use strict;
use warnings;

our $VERSION = 5.54;

use base qw(Exporter);
our @EXPORT_OK = qw(
  _list_algorithms
  _reversetranslate_balanced
  _reversetranslate_high
  _reversetranslate_random
);
our %EXPORT_TAGS =  (GD=> \@EXPORT_OK);

=head2 _list_algorithms

=cut

sub _list_algorithms
{
  my %hsh =
  (
    balanced => 'weighted averages',
    high     => 'uniformly most used',
    random   => 'random',
  );
  return \%hsh;
}

=head2 _reversetranslate_balanced

=cut

sub _reversetranslate_balanced
{
  my ($reverse_codon_table, $rscu_table, $pepseq) = @_;

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

  my $newseq = q{};
  $newseq .= _weighted_rand($changehsh{$_}) foreach (split q{}, $pepseq);
  return $newseq;
}

=head2 _reversetranslate_high

=cut

sub _reversetranslate_high
{
  my ($reverse_codon_table, $rscu_table, $pepseq) = @_;
  my $aa_highs = {};
  foreach my $aa (keys %$reverse_codon_table)
  {
    my $myrscu = -1;
    foreach my $codon (@{$reverse_codon_table->{$aa}})
    {
      if ($rscu_table->{$codon} > $myrscu)
      {
        $aa_highs->{$aa} = $codon;
        $myrscu = $rscu_table->{$codon};
      }
    }
  }
  my $newseq = q{};
  $newseq .= $aa_highs->{$_} foreach (split q{}, $pepseq);
  return $newseq;
}

=head2 _reversetranslate_random

=cut

sub _reversetranslate_random
{
  my ($reverse_codon_table, $rscu_table, $pepseq) = @_;

  my $cod_highs = {};
  foreach my $aa (keys %{$reverse_codon_table})
  {
    $cod_highs->{$aa} = [];
    foreach my $codon (@{$reverse_codon_table->{$aa}})
    {
        push @{$cod_highs->{$aa}}, $codon;
    }
  }

  my $newseq = q{};
  foreach my $aa (split q{}, $pepseq)
  {
    my $index = _random_index(scalar(@{$cod_highs->{$aa}}));
    $newseq .= $cod_highs->{$aa}->[$index];
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
