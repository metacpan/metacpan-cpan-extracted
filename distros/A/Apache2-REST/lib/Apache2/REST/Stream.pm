package Apache2::REST::Stream;
use strict;

=head2 new

Returns a new empty instance.

=cut

sub new{
    my ($class) = @_;
    return bless {} , $class;
}

=head2 nextChunk

Returns the nextChunk of data to output to the client.

This may return:

 - A reference on a chunk of data (a hash, an array, etc..)

 - A string of bytes. This is usefull when you force using
   a binary writer (by using $req->requestedFormat('bin') in your handler)
 
 - undef if the end of the stream is reached.

Implement this in application specific subclasses (Or use one of the provided subclasses if your data source is compatible)

=cut

sub nextChunk{
    my ($self) = @_;
    confess("Please implement me in an application specific subclass");
}

1;
