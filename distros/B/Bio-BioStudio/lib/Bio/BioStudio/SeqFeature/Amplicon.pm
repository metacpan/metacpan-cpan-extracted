#
# BioStudio restriction finding functions
#

=head1 NAME

Bio::BioStudio::SeqFeature::Amplicon - a feature representing a pair of PCRTags

=head1 VERSION

Version 3.00

=head1 DESCRIPTION

BioStudio functions

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::SeqFeature::Amplicon;

use strict;
use warnings;

use base qw(Bio::DB::SeqFeature);

=head2 new

=cut

sub new
{
  my ($caller, @args) = @_;
  my $self = $caller->SUPER::new(@args);
  
  my ($ingene, $uptag, $dntag) =
      $self->_rearrange([qw(INGENE UPTAG DNTAG)], @args);
  $self->primary_tag('PCR_product');
  $self->source('BS');
  $self->ingene($ingene) if defined $ingene;
  $self->uptag($uptag) if defined $uptag;
  $self->dntag($dntag) if defined $dntag;
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

=head2 uptag

=cut

sub uptag
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to uptag');
    }
    $self->remove_tag('uptag') if ($self->has_tag('uptag'));
    $self->add_tag_value('uptag', $value);
  }
  return join q{}, $self->get_tag_values('uptag');
}

=head2 dntag

=cut

sub dntag
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to dntag');
    }
    $self->remove_tag('dntag') if ($self->has_tag('dntag'));
    $self->add_tag_value('dntag', $value);
  }
  return join q{}, $self->get_tag_values('dntag');
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
