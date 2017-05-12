package Apache2::REST::Writer::bin ;
use strict ;

use JSON::XS ;

use Data::Dumper ;

=head1 NAME

Apache2::REST::Writer::bin - Apache2::REST::Response Writer for binary

=head1 DESCRIPTION

This writer returns the binary part of the response.
If the bin_mimetype of the response is set, it returns this mimetype.
Otherwise application/bin is returned

=cut

=head2 new

=cut

sub new{
    my ( $class ) = @_;
    return bless {} , $class;
}

=head2 mimeType

Getter

=cut

sub mimeType{
    my ( $self , $resp ) = @_ ;
    if ( $resp->binMimeType()){
        return $resp->binMimeType() ;
    }
    return 'application/bin' ;
}

=head2 asBytes

Returns the response as json UTF8 bytes for output.

=cut

sub asBytes{
    my ($self,  $resp ) = @_ ;
    
    return $resp->bin() ;
    
}

1;
