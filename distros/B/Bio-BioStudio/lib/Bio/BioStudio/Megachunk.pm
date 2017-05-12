#
# BioStudio module for sequence segmentation
#

=head1 NAME

Bio::BioStudio::Megachunk

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>

=cut

package Bio::BioStudio::Megachunk;

use strict;
use warnings;

use base qw(Bio::Root::Root);

our $VERSION = 2.10;
my $enztype = 'Bio::BioStudio::RestrictionEnzyme';
my $markertype = 'Bio::BioStudio::Marker';

=head1 CONSTRUCTORS

=head2 new

 Title   : new
 Function:
 Returns : a new Bio::BioStudio::Megachunk object
 Args    :

=cut

sub new
{
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);

  bless $self, $class;

  my ($name, $excisor, $frange, $trange, $start, $end, $marker, $omarker,
      $prevenz, $chunks, $markercount, $firstmarker, $lastlastpos, $pexcisor) =
     $self->_rearrange([qw(NAME
                           EXCISOR
                           FRANGE
                           TRANGE
                           START
                           END
                           MARKER
                           OMARKER
                           PREVENZ
                           CHUNKS
                           MARKERCOUNT
                           FIRSTMARKER
                           LASTLASTPOS
                           PEXCISOR)], @args);

  $marker && $self->marker($marker);
  $omarker && $self->omarker($omarker);
  $name && $self->name($name);
  $frange && $self->frange($frange);

  $lastlastpos && $self->lastlastpos($lastlastpos);
  $firstmarker && $self->firstmarker($firstmarker);
  $markercount && $self->markercount($markercount);
  $chunks && $self->chunks($chunks);
  $end && $self->end($end);
  $start && $self->start($start);
  $trange && $self->trange($trange);
  $excisor && $self->excisor($excisor);
  $pexcisor && $self->pexcisor($pexcisor);

  return $self;
}

=head1 FUNCTIONS

=head1 ACCESSORS

=head2 marker

=cut

sub marker
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->throw('object isa ' . ref $value . ' not a ' . $markertype)
      unless $value->isa($markertype);
    $self->{marker} = $value;
  }
  return $self->{marker};
}

=head2 omarker

=cut

sub omarker
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->throw('object isa ' . ref $value . ' not a ' . $markertype)
      unless $value->isa($markertype);
    $self->{omarker} = $value;
  }
  return $self->{omarker};
}

=head2 prevenz

=cut

sub prevenz
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->throw('object isa ' . ref $value . ' not a ' . $enztype)
      unless $value->isa($enztype);
    $self->{prevenz} = $value;
  }
  return $self->{prevenz};
}

=head2 excisor

=cut

sub excisor
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->throw('object isa ' . ref $value . ' not a ' . $enztype)
      unless $value->isa($enztype);
    $self->{excisor} = $value;
  }
  return $self->{excisor};
}

=head2 pexcisor

=cut

sub pexcisor
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->throw('object isa ' . ref $value . ' not a ' . $enztype)
      unless $value->isa($enztype);
    $self->{pexcisor} = $value;
  }
  return $self->{pexcisor};
}

=head2 name

=cut

sub name
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{name} = $value;
  }
  return $self->{name};
}

=head2 frange

=cut

sub frange
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{frange} = $value;
  }
  return $self->{frange};
}

=head2 trange

=cut

sub trange
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{trange} = $value;
  }
  return $self->{trange};
}

=head2 start

=cut

sub start
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{start} = $value;
  }
  return $self->{start};
}

=head2 end

=cut

sub end
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{end} = $value;
  }
  return $self->{end};
}

=head2 chunks

=cut

sub chunks
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{chunks} = $value;
  }
  return $self->{chunks};
}

=head2 markercount

=cut

sub markercount
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{markercount} = $value;
  }
  return $self->{markercount};
}

=head2 firstmarker

=cut

sub firstmarker
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{firstmarker} = $value;
  }
  return $self->{firstmarker};
}

=head2 lastlastpos

=cut

sub lastlastpos
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{lastlastpos} = $value;
  }
  return $self->{lastlastpos};
}

=head2 chunknum

=cut

sub chunknum
{
  my ($self) = @_;
  return scalar @{$self->chunks};
}

=head2 firstchunk

=cut

sub firstchunk
{
  my ($self) = @_;
  return $self->chunks->[0];
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
