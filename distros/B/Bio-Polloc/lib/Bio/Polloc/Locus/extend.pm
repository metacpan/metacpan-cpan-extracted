=head1 NAME

Bio::Polloc::Locus::extend - A feature based on another one

=head1 DESCRIPTION

A feature of a sequence, inferred by similarity or surrounding
regions similar to those of a known feature.  Implements
L<Bio::Polloc::LocusI>.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Locus::extend;
use base qw(Bio::Polloc::LocusI);
use strict;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=head2 new

Creates a B<Bio::Polloc::Locus::repeat> object.

=head3 Arguments

=over

=item -basefeature I<Bio::Polloc::LocusI object>

The reference feature or part of the reference collection.

=item -score I<float>

The score of extension (bit-score on BLAST or score on HMMer, for example).

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}


=head2 basefeature

Gets/sets the reference feature of the extension.  Be careful, this can also
refer to one feature in a collection of reference.  Avoid using specific data
from this feature.

=head3 Arguments

The reference feature (L<Bio::Polloc::LocusI> object, optional).

=head3 Returns

The reference feature (L<Bio::Polloc::LocusI> object or undef).

=cut

sub basefeature {
   my($self,$value) = @_;
   if (defined $value){
      $self->{'_basefeature'} = $value;
      $self->family($value->family);
   }
   return $self->{'_basefeature'};
}


=head2 score

Gets/sets the score.

=head3 Arguments

The score (float, optional).

=head3 Returns

The score (float or undef).

=cut

sub score {
   my($self,$value) = @_;
   $self->{'_score'} = $value+0 if defined $value;
   return $self->{'_score'};
}

=head2 distance

Tries to calculate the distance using the base-feature's C<distance()>
method.  See L<Bio::Polloc::LocusI->distance()>.

=head3 Throws

L<Bio::Polloc::Polloc::Error>.

=cut

sub distance {
   my ($self, @args) = @_;
   $self->throw('Impossible to find a base feature.') unless defined $self->basefeature;
   return $self->basefeature->distance(-locusref=>$self, @args);
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   my($basefeature,$score) = $self->_rearrange([qw(BASEFEATURE SCORE)], @args);
   $self->type('extend');
   $self->comments("Extended feature");
   $self->basefeature($basefeature);
   $self->score($score);
}

1;
