#
# Graphing for GeneDesign
#

=head1 NAME

Bio::GeneDesign::Graph

=head1 VERSION

Version 5.56

=head1 DESCRIPTION

make graphs

=head1 AUTHOR

Sarah Richardson <SMRichardson@lbl.gov>.

=cut

package Bio::GeneDesign::Graph;
require Exporter;

use GD::Graph::lines;
use GD::Graph::colour qw(sorted_colour_list);
use GD::Image;

use strict;
use warnings;

our $VERSION = 5.56;

use base qw(Exporter);
our @EXPORT_OK = qw(
  _make_graph
  _dotplot
  $VERSION
);
our %EXPORT_TAGS =  (GD => \@EXPORT_OK);


=head1 Functions

=head2 _make_graph()

=cut

sub _make_graph
{
  my ($arrref, $window, $orgname, $codon_t, $rscu_t, $revcodon_t) = @_;

  my @sizes = sort {$b <=> $a} map {length($_->seq)} @$arrref;
  my $maxlen = $sizes[0];

  my $graph = GD::Graph::lines->new(1024, 768);
  my @colors = reverse sorted_colour_list(29);
  $graph->set(
    x_label           => 'Window Position (Codon Offset)',
    y_label           => 'Average Relative Synonymous Codon Usage Value',
    title             => "Sliding window of $window using $orgname RSCU values",
    y_max_value       => 1,
    y_min_value       => 0,
    tick_length       => 3,
    y_tick_number     => 1,
    x_label_position  => 0.5,
    y_label_skip      => 0.1,
    x_label_skip      => int($maxlen/50),
    markers           => [1],
    line_width        => 2,
    marker_size       => 2,
    dclrs             => \@colors,
  ) || croak $graph->error;

  my $data = [];
  my @legend;
  my $first = 0;
  my %AAfams = map {$_ => scalar(@{$revcodon_t->{$codon_t->{$_}}})}
               keys %$codon_t;
  my %perc_t = map {$_ => $rscu_t->{$_} / $AAfams{$_}}
               keys %$codon_t;

  foreach my $seqobj (@$arrref)
  {
    my ($x, $y)  = index_codon_percentages($seqobj->seq, $window, \%perc_t);
    push @$data, $x if ($first == 0);
    push @$data, $y;
    $first++;
    push @legend, $seqobj->id;
  }
  $graph->set_legend(@legend);
  my $format = $graph->export_format;
  return ($graph->plot($data)->$format(), $format);
}

=head2 dotplot()

#NO UNIT TESTS

=cut

sub _dotplot
{
  my ($seq1, $seq2, $winsize, $stringency, $outfile) = @_;
  my $Lseq1 = length($seq1);
  my $Lseq2 = length($seq2);

  my $BitMap = GD::Image->new($Lseq1, $Lseq2);

  my $white = $BitMap->colorAllocate(255,255,255);
  my $black = $BitMap->colorAllocate(0,0,0);

  $BitMap->transparent($white);

  for (my $i = 0; $i < $Lseq1 - $winsize; $i++)
  {
    for (my $j = 0; $j < $Lseq2 - $winsize; $j++)
    {
      my $match = 0;
      for (my $w = 0; $w < $winsize; $w++)
      {
        if (substr($seq1, $i + $w, 1) eq substr($seq2, $j + $w, 1))
        {
          $match++;
        }
      }
      if (100 * ($match / $winsize) >= $stringency)
      {
        $BitMap->setPixel($i, $j, $black);
      }
    }
  }
  return $BitMap->png;

  #open   (my $IMG, '>', $outfile) or croak $!;
  #binmode $IMG;
  #print   $IMG $BitMap->png;
  #close   $IMG;
  #return;
}

=head2 index_codon_percentages()

Generates two arrays for x and y values of a graph of codon percentage values.

  in: dna sequence (string),
      window size (integer),
      codon percentage table (hash reference)
  out: x values (array reference), y values (array reference)

=cut

sub index_codon_percentages
{
  my ($ntseq, $window, $perc_t) = @_;
  my @xvalues; my @yvalues;
  my $index; my $sum;
  for (my $x = int($window * (3 / 2)) - 3;
          $x < (length($ntseq) - 3 * (int($window * (3 / 2)) - 3));
          $x += 3)
  {
    $sum = 0;
    for(my $y = $x; $y < 3*$window + $x; $y += 3)
    {
      $sum += $perc_t->{substr($ntseq, $y, 3)};
    }
    $sum = $sum / $window;
    $index = ($x / 3) + 1;
    push @xvalues, $index;
    push @yvalues, $sum;
  }
  return (\@xvalues, \@yvalues);
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

