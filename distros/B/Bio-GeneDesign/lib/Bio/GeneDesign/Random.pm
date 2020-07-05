#
# GeneDesign libraries for Random DNA generation
#

=head1 NAME

GeneDesign::Random

=head1 VERSION

Version 5.56

=head1 DESCRIPTION

Random DNA Generators

=head1 AUTHOR

Sarah Richardson <SMRichardson@lbl.gov>

=cut

package Bio::GeneDesign::Random;
require Exporter;

use Bio::GeneDesign::Codons qw(_find_in_frame);
use Bio::GeneDesign::Basic qw(@BASES %NTIDES);
use List::Util qw(shuffle);

use strict;
use warnings;

our $VERSION = 5.56;

use base qw(Exporter);
our @EXPORT_OK = qw(
  _randomDNA
  _randombase
  _randombase_weighted
  _replace_ambiguous_bases
  _weighted_rand
  _random_index
);
our %EXPORT_TAGS =  (GD => \@EXPORT_OK);

=head1 Functions

=head2 _randomDNA()

  takes a target length and a GC percentage and generates a random nucleotide
  sequence, with or without stops in the first frame
  in: nucleotide sequence length (scalar),
      GC percentage (0 <= scalar <= 100),
      stop codon prevention(0 stops allowed, else no stops),
      codon table (hash reference)
  out: nucleotide sequence (string)

=cut

sub _randomDNA
{
  my ($len, $GCperc, $stopswit, $codon_t) = @_;

  return q{} if ($len == 0);
  return _randombase_weighted($GCperc) if ($len == 1);

  #GC
  my $GCtotal = sprintf "%.0f",  $GCperc * $len / 100;
  my $Gcount  = sprintf "%.0f", rand( $GCtotal );
  my $Gstr = 'G' x $Gcount;
  my $Ccount  = $GCtotal - $Gcount;
  my $Cstr = 'C' x $Ccount;

  #AT
  my $ATtotal = $len - $GCtotal;
  my $Acount  = sprintf "%.0f", rand( $ATtotal );
  my $Astr = 'A' x $Acount;
  my $Tcount  = $ATtotal - $Acount;
  my $Tstr = 'T' x $Tcount;

  my @randomarray = shuffle( split( '', $Gstr . $Cstr . $Astr . $Tstr) );
  my $DNA = join('', @randomarray);

  if ($stopswit)
  {
    my $stophsh = _find_in_frame($DNA, "*", $codon_t);
    while (scalar keys %{$stophsh})
    {
      foreach my $pos (keys %{$stophsh})
      {
        my $bit = substr $DNA, $pos, 3;
        substr $DNA, $pos, 3, scalar reverse $bit;
        if (int(rand(1)+.5) == 1)
        {
          my $bat = substr $DNA, $pos, 2;
          substr $DNA, $pos, 2, scalar reverse$bat;
        }
      }
      $stophsh = _find_in_frame($DNA, "*", $codon_t);
    }
  }
  return $DNA;
}

=head2 _randombase()

  when you just want one random base

=cut

sub _randombase
{
  my $int = _random_index(4);
  return $BASES[$int];
}

=head2 _random_weighted_base()

  when you just want one random but weighted base

=cut

sub _randombase_weighted
{
  my ($GCp) = @_;
  return _randombase() unless ($GCp);

  my $GCcount = $GCp/200 ;
  my $ATcount = (100-$GCp)/200;
  my $weight = {G => $GCcount, C => $GCcount, T => $ATcount, A => $ATcount};
  return _weighted_rand($weight);
}

=head2 _weighted_rand()

=cut

sub _weighted_rand
{
  my ($dist) = @_;
  croak ("no distribution provided") unless ($dist);
  my ($key, $weight);

  while (1)
  {
    my $rand = rand;
    while ( ($key, $weight) = each %$dist )
    {
      return $key if ($rand -= $weight) < 0;
    }
  }
  return;
}

=head2 _replace_ambiguous_bases

=cut

sub _replace_ambiguous_bases
{
  my ($seq) = @_;
  my $new = q{};
  foreach my $char (split(q{}, $seq))
  {
    my @class = @{$NTIDES{$char}};
    my $index = _random_index(scalar(@class));
    $new .= $class[$index];
  }
  return $new;
}

=head2 _random_index

=cut

sub _random_index
{
  my ($array_size) = @_;
  return (sprintf "%.0f", rand($array_size)) % $array_size;
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
