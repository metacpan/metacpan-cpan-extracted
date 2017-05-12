=head1 NAME

Bio::BioStudio::SeqFeature::RestrictionSite

=head1 VERSION

Version 3.00

=head1 DESCRIPTION

BioStudio functions

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::SeqFeature::RestrictionSite;

use strict;
use warnings;

use base qw(Bio::DB::SeqFeature);

=head2 new

=cut

sub new
{
  my ($caller, @args) = @_;
  my $self = $caller->SUPER::new(@args);
  
  my ($presence, $infeat, $enzyme, $ohang, $peptide, $ohangoffset,
      $megachunk, $chunks, $remove, $wtseq, $newseq) =
                   $self->_rearrange([qw(PRESENCE INFEAT ENZYME WANTHANG PEPTIDE
                   OHANGOFFSET MEGACHUNK CHUNKS REMOVE WTSEQ NEWSEQ)], @args);
  $self->primary_tag('enzyme_recognition_site');
  $self->source('BS');
  $self->presence($presence) if defined $presence;
  $self->infeat($infeat) if defined $infeat;
  $self->enzyme($enzyme) if defined $enzyme;
  $self->ohang($ohang) if defined $ohang;
  $self->peptide($peptide) if defined $peptide;
  $self->ohangoffset($ohangoffset) if defined $ohangoffset;
  $self->megachunk($megachunk) if defined $megachunk;
  $self->chunks($chunks) if defined $chunks;
  $self->remove($remove) if defined $remove;
  $self->wtseq($wtseq) if defined $wtseq;
  $self->newseq($newseq) if defined $newseq;
  return $self;
}

=head2 presence

=cut

sub presence
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to presence');
    }
    $self->remove_tag('presence') if ($self->has_tag('presence'));
    $self->add_tag_value('presence', $value);
  }
  return join q{}, $self->get_tag_values('presence');
}

=head2 infeat

=cut

sub infeat
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to infeat');
    }
    $self->remove_tag('infeat') if ($self->has_tag('infeat'));
    $self->add_tag_value('infeat', $value);
  }
  return join q{}, $self->get_tag_values('infeat');
}

=head2 enzyme

=cut

sub enzyme
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to enzyme');
    }
    $self->remove_tag('enzyme') if ($self->has_tag('enzyme'));
    $self->add_tag_value('enzyme', $value);
  }
  return join q{}, $self->get_tag_values('enzyme');
}

=head2 ohang

=cut

sub ohang
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to ohang');
    }
    $self->remove_tag('ohang') if ($self->has_tag('ohang'));
    $self->add_tag_value('ohang', $value);
  }
  return join q{}, $self->get_tag_values('ohang');
}

=head2 peptide

=cut

sub peptide
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to peptide');
    }
    $self->remove_tag('peptide') if ($self->has_tag('peptide'));
    $self->add_tag_value('peptide', $value);
  }
  return join q{}, $self->get_tag_values('peptide');
}

=head2 ohangoffset

=cut

sub ohangoffset
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to ohangoffset');
    }
    $self->remove_tag('ohangoffset') if ($self->has_tag('ohangoffset'));
    $self->add_tag_value('ohangoffset', $value);
  }
  return join q{}, $self->get_tag_values('ohangoffset');
}

=head2 megachunk

=cut

sub megachunk
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to megachunk');
    }
    $self->remove_tag('megachunk') if ($self->has_tag('megachunk'));
    $self->add_tag_value('megachunk', $value);
  }
  return join q{}, $self->get_tag_values('megachunk');
}

=head2 chunks

=cut

sub chunks
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value eq 'ARRAY')
    {
      my @arr = @{$value};
      $self->add_tag_value('chunks', $_) foreach (@arr);
    }
    else
    {
      $self->add_tag_value('chunks', $value);
    }
  }
  return join q{}, $self->get_tag_values('chunks');
}

=head2 remove

=cut

sub remove
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value eq 'ARRAY')
    {
      my @arr = @{$value};
      $self->add_tag_value('remove', $_) foreach (@arr);
    }
    else
    {
      $self->add_tag_value('remove', $value);
    }
  }
  return join q{}, $self->get_tag_values('remove');
}

=head2 wtseq

=cut

sub wtseq
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to wtseq');
    }
    $self->remove_tag('wtseq') if ($self->has_tag('wtseq'));
    $self->add_tag_value('wtseq', $value);
  }
  return join q{}, $self->get_tag_values('wtseq');
}

=head2 newseq

=cut

sub newseq
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to newseq');
    }
    $self->remove_tag('newseq') if ($self->has_tag('newseq'));
    $self->add_tag_value('newseq', $value);
  }
  return join q{}, $self->get_tag_values('newseq');
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Joint BioEnergy 
Institute, the Lawrence Berkeley National Laboratory, the Department of Energy, 
and the BioStudio developers may not be used to endorse or promote products 
derived from this software without specific prior written permission.

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
