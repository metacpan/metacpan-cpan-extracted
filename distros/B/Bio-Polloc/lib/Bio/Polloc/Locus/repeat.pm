=head1 NAME

Bio::Polloc::Locus::repeat - A repetitive locus

=head1 DESCRIPTION

A repeatitive locus.  Implements L<Bio::Polloc::LocusI>.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Locus::repeat;
use base qw(Bio::Polloc::LocusI);
use strict;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=head2 new

Creates a B<Bio::Polloc::Locus::repeat> object.

=head3 Arguments

=over

=item -period I<float>

The period of the repeat (units length).

=item -exponent I<float>

The exponent (No of units).

=item -error I<float>

Mismatches percentage.

=item -repeats I<str>

Repetitive sequences, repeats space-separated.

=item -consensus I<str>

Repeats consensus.

=back

=head3 Returns

A L<Bio::Polloc::Locus::repeat> object.

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}


=head2 period

Gets/sets the period of the repeat.  I<I.e.>, the size of each repeat.

=head3 Arguments

The period (int, optional).

=head3 Returns

The period (int or undef)

=cut

sub period {
   my($self,$value) = @_;
   $self->{'_period'} = $value+0 if defined $value;
   return $self->{'_period'};
}


=head2 exponent

Gets/sets the exponent of the repeat.  I<I.e.>, the number of times the repeat
is repeated.

=head3 Arguments

The exponent (int, optional).

=head3 Returns

The exponent (int or undef).

=cut

sub exponent {
   my($self,$value) = @_;
   $self->{'_exponent'} = $value if defined $value;
   return $self->{'_exponent'};
}


=head2 repeats

Sets/gets the repetitive sequence (each repeat separated by spaces).

=head3 Arguments

The repetitive sequence (str, optional).

=head3 Returns

The repetitive sequence (str or undef).

=cut

sub repeats {
   my($self,$value) = @_;
   $self->{'_repeats'} = $value if defined $value;
   return $self->{'_repeats'};
}


=head2 consensus

Sets/gets the consensus repeat.

=head3 Arguments

The consensus sequence (str, optional).

=head3 Returns

The consensus sequence (str or undef).

=cut

sub consensus {
   my($self,$value) = @_;
   $self->{'_consensus'} = $value if defined $value;
   return $self->{'_consensus'};
}

=head2 error

Gets/sets the error rate of the repeat.  I<I.e.>, the percentage of mismatches.

=head3 Arguments

The error (float).

=head3 Returns

The error (float or undef).

=cut

sub error {
   my($self,$value) = @_;
   $self->{'_error'} = $value+0 if defined $value;
   return $self->{'_error'};
}


=head2 score

Gets/sets the score

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

Returns the difference in length with the given locus.

=head3 Arguments

=over

=item -locus I<Bio::Polloc::LocusI object>

The locus to compare with.

=item -locusref I<Bio::Polloc::LocusI object>

The reference locus.  If set, replaces the current loaded object.

=item -units I<bool (int)>

If true, returns the difference in the number of repeat units, not
in base pairs.  This flag requires the loci to be
L<Bio::Polloc::Locus::repeat> objects.

=back

=head3 Returns

Float, the difference in length.

=head3 Throws

L<Bio::Polloc::Polloc::Error> if no locus or the loci are not of the
proper type.

=cut

sub distance {
   my($self, @args) = @_;
   my($locus,$locusref,$units) = $self->_rearrange([qw(LOCUS LOCUSREF UNITS)], @args);
   $locusref = $self unless defined $locusref;
   
   # Check input
   $self->throw('You must set the target locus') unless defined $locus;
   $self->throw('Target locus must be an object', $locus) unless UNIVERSAL::can($locus, 'isa');
   $self->throw('Target locus must be Bio::Polloc::LocusI', $locus) unless $locus->isa('Bio::Polloc::LocusI');
   $self->throw('Reference locus must be an object', $locusref) unless UNIVERSAL::can($locusref, 'isa');
   $self->throw('Reference locus must be Bio::Polloc::LocusI', $locusref) unless $locusref->isa('Bio::Polloc::LocusI');
   
   my $dist = 0;
   if($units){
      $self->throw('Unable to get the target exponent', $locus)
      		unless $locus->can('exponent') and defined $locus->exponent;
      $self->throw('Unable to get the reference exponent', $locusref)
      		unless $locusref->can('exponent') and defined $locusref->exponent;
      $dist = abs $locus->exponent - $locusref->exponent;
   }else{
      $self->throw('Unable to get the target coordinates', $locus)
   		unless defined $locus->from and defined $locus->to;
      $self->throw('Unable to get the reference coordinates', $locusref)
   		unless defined $locusref->from and defined $locusref->to;
      $dist = abs( abs($locus->to - $locus->from) - abs($locusref->to - $locusref->from) );
   }
   $self->debug("Distance: $dist");
   return $dist;
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   my($period,$exponent,$score,$error,$repeats,$consensus) = $self->_rearrange(
   		[qw(PERIOD EXPONENT SCORE ERROR REPEATS CONSENSUS)], @args);
   $self->type('repeat');
   $self->period($period);
   $self->comments("Period=" . $self->period) if defined $self->period;
   $self->exponent($exponent);
   $self->comments("Exponent=" . $self->exponent) if defined $self->exponent;
   $self->score($score);
   $self->comments("Score=" . $self->score) if defined $self->score;
   $self->error($error);
   $self->comments("Error=" . $self->error) if defined $self->error;
   $self->repeats($repeats);
   $self->consensus($consensus);
}

1;
