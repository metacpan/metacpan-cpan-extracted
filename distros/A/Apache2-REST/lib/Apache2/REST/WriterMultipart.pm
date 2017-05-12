package Apache2::REST::WriterMultipart;
use strict;
use warnings;
use Carp;

use Apache2::Const;

# The boundary we'll use in between our multipart chunks
our $BOUNDARY = 'facedeadbeef';

=head2 new

You can override this if you like but remember
it has to build an object without arguments.

=cut

sub new{
    my ( $class ) = @_;
    return bless {} , $class;
}


=head2 mimeType

Returns the mime type this writer will output.

It is called like this by the framework:

   $this->mimeType($resp) ;

This defaults to multipart/x-mixed-replace (makes it easy to test in the browser)
but can be overridden.  For example, one might want to use plain
multipart/mixed.

=cut

sub mimeType{
    my ( $self , $resp )=@_;
    return 'multipart/x-mixed-replace';
}

=head2 getPreambleBytes

Returns the bytes the framework has to write back to client as a Stream preamble.
This defaults to "" for the multipart writer since data typically isn't
send with the initial response (it doesn't really have a formal mime type at
that point).  Normally the first relevant content is the first "part" which
comes with it's own headers.

It is called by the framework like this ($resp is a Apache2::REST::Response):

    $this->getPreambleBytes($resp) ;

=cut

sub getPreambleBytes{
    my ($self,  $resp ) = @_ ;
    return Encode::encode_utf8("");
}


=head2 getNextPart

Returns the next part of the multipart response, or undef at the end of the stream.
The chunk should be a hash containing 'mimetype' and 'data'.  This allows
the subclass to dictate the mimetype of every chunk and, thus, they
can all be different if desired (an xml doc, then an audio file for ex.).

Called by the framework like that:

while( defined my $chunk = $this->getNextChunk($response) ){
    my $mimetype = $chunk->{'mimetype'};
    my $bytes    = $chunk->{'data'};
  ...
}

=cut

sub getNextPart{
    my ($self, $resp) = @_;
    confess("Please implement me in an application subclass");
}

=head2 getPostambleBytes

Returns the last bytes to write in the stream when the stream is finished.
This defaults to "" for the multipart writer and probably shouldn't be
changed since it would sandwhich data between the final chunk and the final
boundary string.

Called by the framework like that:

$this->getPostambleBytes($response);

=cut

sub getPostambleBytes{
    my ($self, $resp) = @_;
    return Encode::encode_utf8("");
}

=head2 handleModPerlResponse

Handles writing this response in a mod perl request object at response time.
This also handles the additional work of crafting the correct multipart
boundaries, etc.

Beware, this method switches STDOUT to binmode.

=cut

sub handleModPerlResponse{
    my ($self , $r , $resp , $retCode ) = @_;

    # Add the boundary stuff to the content type value
    my $content_type = $self->mimeType($resp) . "; boundary=\"$BOUNDARY\"";
    $r->content_type($content_type);
    $resp->cleanup();
    
    if ( $retCode && ( $retCode  != Apache2::Const::HTTP_OK ) ){
        $r->status($retCode);
    }

    select(STDOUT);
    $| = 0;
    binmode STDOUT;
    print $self->getPreambleBytes($resp);
    $r->rflush();

    # Note: in the multipart case, each chunk is expected to be
    #       {'mimetype' => '...', 'data' => '...'}
    while (defined (my $nextChunk = $self->getNextPart($resp))) {
        my $mimetype = $nextChunk->{'mimetype'};
        my $data = $nextChunk->{'data'};
        my $content_length = length($data) + 2; # we'll need this plus the \r\n
        print "--$BOUNDARY\r\n";
        print "Content-Type: $mimetype\r\n";
        print "Content-Length: $content_length\r\n\r\n";
        print $data;
        print "\r\n";
        $r->rflush();
    }
    print $self->getPostambleBytes($resp);  # could be bad if this is not empty?
    print "--$BOUNDARY--\r\n";
    $r->rflush();
    
    return Apache2::Const::OK;
}

1;
