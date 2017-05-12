#
# BioStudio restriction finding functions
#

=head1 NAME

Bio::BioStudio::SeqFeature::Tag - a feature representing a PCRTag

=head1 VERSION

Version 3.00

=head1 DESCRIPTION

BioStudio functions

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::SeqFeature::Tag;

use strict;
use warnings;

use base qw(Bio::DB::SeqFeature);

=head2 new

=cut

sub new
{
  my ($caller, @args) = @_;
  my $self = $caller->SUPER::new(@args);
  
  my ($ingene, $wtseq, $newseq, $difference, $translation) =
    $self->_rearrange([qw(INGENE WTSEQ NEWSEQ DIFFERENCE TRANSLATION)], @args);
  $self->primary_tag('tag');
  $self->source('BS');
  $self->ingene($ingene) if defined $ingene;
  $self->wtseq($wtseq) if defined $wtseq;
  $self->newseq($newseq) if defined $newseq;
  $self->difference($difference) if defined $difference;
  $self->translation($translation) if defined $translation;
  return $self;
}

=head2 ingene

=cut

sub ingene
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to ingene');
    }
    $self->remove_tag('ingene') if ($self->has_tag('ingene'));
    $self->add_tag_value('ingene', $value);
  }
  return join q{}, $self->get_tag_values('ingene');
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

=head2 difference

=cut

sub difference
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to difference');
    }
    $self->remove_tag('difference') if ($self->has_tag('difference'));
    $self->add_tag_value('difference', $value);
  }
  return join q{}, $self->get_tag_values('difference');
}

=head2 translation

=cut

sub translation
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to translation');
    }
    $self->remove_tag('translation') if ($self->has_tag('translation'));
    $self->add_tag_value('translation', $value);
  }
  return join q{}, $self->get_tag_values('translation');
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
