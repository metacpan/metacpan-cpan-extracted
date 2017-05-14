package Bio::Gonzales::PrimarySeqIX;

use strict;
use warnings;
use Bio::Gonzales::Tools::SeqMask;

our $VERSION = '0.0546'; # VERSION

sub Bio::PrimarySeqI::clone {
    my ($self) = @_;
    return clone($self);
}

sub clone {
    my ($so) = @_;
    my $seqclass;
    if ( $so->can_call_new() ) {
        $seqclass = ref($so);
    } else {
        $seqclass = 'Bio::PrimarySeq';
        $so->_attempt_to_load_Seq();
    }

    my $out = $seqclass->new(
        '-seq'              => $so->seq,
        '-display_id'       => $so->display_id,
        '-accession_number' => $so->accession_number,
        '-alphabet'         => $so->alphabet,
        '-desc'             => $so->desc(),
        '-verbose'          => $so->verbose
    );

    return $out;
}

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

sub Bio::PrimarySeqI::mask {
    my ( $self, @args ) = @_;

    return Bio::Gonzales::Tools::SeqMask->new( -seq => $self )->mask(@args)->seq;
}

sub Bio::PrimarySeqI::trunc_masked_ends {
    my ( $self, @args ) = @_;

    return Bio::Gonzales::Tools::SeqMask->new( -seq => $self )->trunc_masked_ends(@args)->seq;
}

1;
