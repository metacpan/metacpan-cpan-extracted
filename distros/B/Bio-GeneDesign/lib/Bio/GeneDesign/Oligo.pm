#
# GeneDesign module for sequence segmentation
#

=head1 NAME

Bio::GeneDesign::Oligo

=head1 VERSION

Version 5.54

=head1 DESCRIPTION


=head1 AUTHOR

Sarah Richardson <SMRichardson@lbl.gov>.

=cut

package Bio::GeneDesign::Oligo;
require Exporter;

use Bio::GeneDesign::Basic qw(:GD);
use strict;
use warnings;

our $VERSION = 5.54;

use base qw(Exporter);
our @EXPORT_OK = qw(
  _make_amplification_primers
  _filter_homopolymer
  _check_for_homopolymer
  $VERSION
);
our %EXPORT_TAGS =  (GD => \@EXPORT_OK);

=head1 Functions

=head2 _filter_homopolymer()

=cut

sub _filter_homopolymer
{
  my ($seqarr, $length) = @_;
  my @newarr = ();
  foreach my $seq (@{$seqarr})
  {
    push @newarr, $seq if (! _check_for_homopolymer($seq, $length));
  }
  return \@newarr;
}

=head2 _check_for_homopolymer()

=cut

sub _check_for_homopolymer
{
  my ($seq, $length) = @_;
  $length = $length || 5;
  return 1 if ($length <= 1);
  return 1 if $seq =~ m{A{$length}|T{$length}|C{$length}|G{$length}}msxi;
  return 0;
}

=head2 _make_amplification_primers()

=cut

sub _make_amplification_primers
{
  my ($sequence, $temperature) = @_;

  my $left_length = 5;
  my $lprimer = substr($sequence, 0, $left_length);
  while (_melt($lprimer) < $temperature)
  {
    $left_length++;
    last if ($left_length > 45);
    $lprimer = substr($sequence, 0, $left_length)
  }

  my $right_end = length($sequence);
  my $right_length = 5;
  my $rprimer = substr($sequence, $right_end - $right_length, $right_length);
  while (_melt($rprimer) < $temperature)
  {
    $right_length++;
    last if ($right_length > 45);
    $rprimer = substr($sequence, $right_end - $right_length, $right_length);
  }
  $rprimer = _complement($rprimer, 1);

  return ($lprimer, $rprimer);
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

