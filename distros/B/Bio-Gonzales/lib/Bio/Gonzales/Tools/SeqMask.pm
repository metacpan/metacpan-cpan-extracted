#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Gonzales::Tools::SeqMask;

use Mouse;

use MouseX::Foreign 'Bio::Root::Root';

with 'Bio::Gonzales::Role::BioPerl::Constructor';

use warnings;
use strict;
use Carp;

our $VERSION = '0.0546'; # VERSION
use 5.010;

has seq => ( is => 'rw' );

=head2 mask

 Title   : mask
 Usage   : $obj->mask(10,40,'Z');
           $obj->mask(10,40);
           $obj->mask($bio_location_obj, 'Z');
           $obj->mask($bio_location_obj);
 Function: masks a sequence region by replacing the respective part with a
           custom character. If the character is omitted, 'X' in case of
           protein and 'N' in case of DNA/RNA alphabet is used to mask the
           sequence region.
 Returns : the object it was invoked on
 Args    : integer for start position
           integer for end position
           custom character to use for masking
                 OR
           Bio::LocationI location for sequence region (strand NOT honored)
           custom character to use for masking
=cut

our %UNKNOWN_CHAR = (
    dna     => 'N',
    rna     => 'N',
    protein => 'X',
);

sub mask {
    my ( $self, $start, $end, $char ) = @_;

    if ( ref($start) && $start->isa('Bio::LocationI') ) {
        my $loc = $start;
        $char = $end;

        for my $subloc ( $loc->each_Location() ) {
            $self->mask( $subloc->start, $subloc->end, $char );
        }
    } else {
        $char = $UNKNOWN_CHAR{ lc( $self->seq->alphabet ) }
            unless ($char);

        $self->seq->subseq(
            -start        => $start,
            -end          => $end,
            -replace_with => $char x ( $end - $start + 1 ),
        );
    }

    return $self;
}

sub trunc_masked_ends {
    my ( $self, $char ) = @_;

    $char = $UNKNOWN_CHAR{ lc( $self->seq->alphabet ) }
        unless ($char);

    my $seq = $self->seq->seq;
    $seq =~ s/^$char+//;
    $seq =~ s/$char+$//;
    $self->seq->seq($seq);
    return $self;
}

1;
