=head1 NAME

Bio::BioStudio::SeqFeature::Megachunk

=head1 VERSION

Version 3.00

=head1 DESCRIPTION

BioStudio functions

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::SeqFeature::Megachunk;

use strict;
use warnings;

use base qw(Bio::DB::SeqFeature);

=head2 new

=cut

sub new
{
  my ($caller, @args) = @_;
  my $self = $caller->SUPER::new(@args);
  
  my ($marker, $excisor) = $self->_rearrange([qw(MARKER EXCISOR)], @args);
  $self->primary_tag('megachunk');
  $self->source('BS');
  $self->marker($marker) if defined $marker;
  $self->excisor($excisor) if defined $excisor;
  return $self;
}

=head2 marker

=cut

sub marker
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to marker');
    }
    $self->remove_tag('marker') if ($self->has_tag('marker'));
    $self->add_tag_value('marker', $value);
  }
  return join q{}, $self->get_tag_values('marker');
}

=head2 excisor

=cut

sub excisor
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    if (ref $value)
    {
      $self->throw('reference passed to excisor');
    }
    $self->remove_tag('excisor') if ($self->has_tag('excisor'));
    $self->add_tag_value('excisor', $value);
  }
  return join q{}, $self->get_tag_values('excisor');
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
