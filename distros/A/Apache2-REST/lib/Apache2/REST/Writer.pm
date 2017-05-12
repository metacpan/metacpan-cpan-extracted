package Apache2::REST::Writer;
use strict;
use warnings;

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

So you can adapt the mime type according to the response to be given.

=cut

sub mimeType{
    my ( $self , $resp )=@_;
    return '' ;
}

=head2 asBytes

Returns the bytes the framework has to write back to client.

It is called by the framework like this ($resp is a Apache2::REST::Response):

    $this->asBytes($resp) ;

=cut

sub asBytes{
    my ($self,  $resp ) = @_ ;
    return '' ;
}


1;
