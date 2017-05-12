package Apache2::REST::Stream::TestStream;
use strict;
use base qw/Apache2::REST::Stream Class::AutoAccess/;

=head2

Builds a new stream that will output $number_of_chunks chunks
of data.

Usage:

    my $stream = Apache2::REST::Stream::TestStream->new($number_of_chunks, $delay_between_chunks);

=cut

sub new{
    my ($class , $number_of_chunks, $delay ) = @_;
    my $self = {
	'number' => $number_of_chunks,
    'delay'  => $delay
    };
    return bless $self , $class;
}

=head2 nextChunk

Returns a hash to be served as a chunk of data.
undef at the end of the stream.

=cut

sub nextChunk{
    my ($self) = @_;
    if($self->number() <= 0){
        return undef;
    }

    # simulate slower streams
    if ($self->{'delay'}) {
        sleep $self->{'delay'};
    }
    $self->number($self->number() - 1);
    return { 'chunk_message' => $self->number().' chunks left' }; 
}

1;
