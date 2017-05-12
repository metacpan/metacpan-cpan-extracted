#
# BioStudio module for sequence segmentation
#

=head1 NAME

Bio::BioStudio::Chunk

=head1 VERSION

Version 1.06

=head1 DESCRIPTION

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>

=cut

package Bio::BioStudio::Chunk;

use strict;
use warnings;

use base qw(Bio::Root::Root);

our $VERSION = 2.10;

=head1 CONSTRUCTORS

=head2 new

All arguments are optional:

    -name      The name of the chunk
   
    -number    The number of the chunk in its megachunk
   
    -prevcand  A L<Bio::BioStudio::RestrictionEnzyme> object corresponding to
               the site at the three prime end of the chunk
   
    -usedenzymes
   
    -usedoverhangs
   
    -enzlist
   
    -bkupenzlist
            
    -enzyme   A L<Bio::BioStudio::RestrictionEnzyme> object corresponding to
              the site at the five prime end of the chunk

=cut

sub new
{
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);

  bless $self, $class;

  my ($name, $number, $prevcand, $usedenzymes, $usedoverhangs, $enzlist,
      $bkupenzlist, $enzyme) =
     $self->_rearrange([qw(NAME NUMBER PREVCAND USED_ENZYMES USED_OVERHANGS
       ENZLIST BKUPENZLIST ENZYME)], @args);

  $name && $self->name($name);
  $number && $self->number($number);
  $prevcand && $self->prevcand($prevcand);
  $usedenzymes && $self->used_enzymes($usedenzymes);
  $usedoverhangs && $self->used_overhangs($usedoverhangs);
  $enzlist && $self->enzlist($enzlist);
  $bkupenzlist && $self->bkupenzlist($bkupenzlist);
  $enzyme && $self->enzyme($enzyme);

  return $self;
}

=head1 FUNCTIONS

=head1 Accessor functions

=head2 prevcand

=cut

sub prevcand
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->throw('object of class ' . ref $value . ' does not implement '.
		    'Bio::BioStudio::RestrictionEnzyme.')
		  unless $value->isa('Bio::BioStudio::RestrictionEnzyme');
    $self->{'prevcand'} = $value;
  }
  return $self->{'prevcand'};
}

=head2 enzyme

=cut

sub enzyme
{
  my ($self, $value) = @_;
  if (defined $value)
  {
	  $self->throw('object of class ' . ref $value . ' does not implement '.
		    'Bio::BioStudio::RestrictionEnzyme.')
		  unless $value->isa('Bio::BioStudio::RestrictionEnzyme');
    $self->{'enzyme'} = $value;
  }
  return $self->{'enzyme'};
}

=head2 name

=cut

sub name
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{'name'} = $value;
  }
  return $self->{'name'};
}

=head2 used_enzymes

=cut

sub used_enzymes
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{'used_enzymes'} = $value;
  }
  return $self->{'used_enzymes'};
}

=head2 used_overhangs

=cut

sub used_overhangs
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{'used_overhangs'} = $value;
  }
  return $self->{'used_overhangs'};
}

=head2 bkupenzlist

=cut

sub bkupenzlist
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{'bkupenzlist'} = $value;
  }
  return $self->{'bkupenzlist'};
}

=head2 enzlist

=cut

sub enzlist
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{'enzlist'} = $value;
  }
  return $self->{'enzlist'};
}

=head2 number

=cut

sub number
{
  my ($self, $value) = @_;
  if (defined $value)
  {
    $self->{'number'} = $value;
  }
  return $self->{'number'};
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* Neither the name of the Johns Hopkins nor the names of the developers may be
used to endorse or promote products derived from this software without specific
prior written permission.

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
