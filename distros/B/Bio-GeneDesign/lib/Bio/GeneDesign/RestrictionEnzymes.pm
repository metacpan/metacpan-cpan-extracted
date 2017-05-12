#
# GeneDesign module for sequence segmentation
#

=head1 NAME

Bio::GeneDesign::RestrictionEnzymes

=head1 VERSION

Version 5.54

=head1 DESCRIPTION

GeneDesign functions for handling restriction enzymes

=head1 AUTHOR

Sarah Richardson <SMRichardson@lbl.gov>

=cut

package Bio::GeneDesign::RestrictionEnzymes;

use Exporter;
use Bio::GeneDesign::Basic qw(:GD);
use Bio::GeneDesign::RestrictionEnzyme;
use Carp;

use strict;
use warnings;

our $VERSION = 5.54;

use base qw(Exporter);
our @EXPORT_OK = qw(
  _define_sites
  _define_site_status
  _parse_enzyme_list
  $VERSION
);
our %EXPORT_TAGS =  (GD => \@EXPORT_OK);

=head2 define_sites()

Generates a hash reference where the keys are enzyme names and the values are
L<Bio::GeneDesign::RestrictionEnzyme> objects.

=cut

sub _define_sites
{
  my ($file) = @_;
  open (my $REFILE, '<', $file) || croak ("Can't find $file!\n");
  my $ref = do { local $/ = <$REFILE> };
  close $REFILE;
  my @data = split(m{\n}x, $ref);
  my %RES;
  my @lines = grep {$_ !~ m{^ \# }x} @data;
  foreach my $line (@lines)
  {
    my ($name, $site, $temp, $inact, $buf1, $buf2, $buf3, $buf4, $bufu, $dam,
        $dcm, $cpg, $score, $star, $vendor, $aggress) = split("\t", $line);
    my $buffhsh = {NEB1 => $buf1, NEB2 => $buf2, NEB3 => $buf3,
                   NEB4 => $buf4, Other => $bufu};
    $star = undef unless ($star eq 'y');
    my $re = Bio::GeneDesign::RestrictionEnzyme->new(
      -id => $name,
      -cutseq => $site,
      -temp   => $temp,
      -tempin => $inact,
      -score  => $score,
      -methdam => $dam,
      -methdcm => $dcm,
      -methcpg => $cpg,
      -staract => $star,
      -vendors => $vendor,
      -buffers => $buffhsh,
      -aggress => $aggress
    );
    $RES{$re->{id}} = $re;
  }
  #Make exclusion lists
  foreach my $re (values %RES)
  {
    my $rid = $re->{id};
    my %excl;
    foreach my $ar (sort grep {$_->{id} ne $rid} values %RES)
    {
      foreach my $arreg (@{$ar->{regex}})
      {
        $excl{$ar->{id}}++ if ($re->{recseq} =~ $arreg)
      }
      foreach my $rereg (@{$re->{regex}})
      {
        $excl{$ar->{id}}++ if ($ar->{recseq} =~ $rereg)
      }
    }
    my @skips = sort keys %excl;
    $re->exclude(\@skips);
  }
  return \%RES;
}

=head2 define_site_status

Generates a hash describing the restriction count of a nucleotide sequence.

  Arguments: nucleotide sequence as a string
             an arrayref of L<Bio::GeneDesign::RestrictionEnzyme> objects

  Returns: reference to a hash where the keys are enzyme ids and the value is
            a count of their occurence in the nucleotide sequence

=cut

sub _define_site_status
{
  my ($seq, $RES) = @_;
  my $SITE_STATUS = {};
  foreach my $re (@{$RES})
  {
    my $tmphsh = $re->positions($seq);
    $SITE_STATUS->{$re->id} = scalar keys %{$tmphsh};
  }
  return $SITE_STATUS;
}

=head2 _parse_enzyme_list

=cut

sub _parse_enzyme_list
{
  my ($path) = @_;
  open (my $REFILE, '<', $path) || croak ("Can't read $path!\n");
  my $ref = do { local $/ = <$REFILE> };
  close $REFILE;
  my @list = split m{\s}x, $ref;
  return \@list;
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
