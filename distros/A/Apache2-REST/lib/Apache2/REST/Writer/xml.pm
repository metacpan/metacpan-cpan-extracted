package Apache2::REST::Writer::xml ;
use strict ;
use XML::Simple ;

use Data::Dumper ;
=head1 NAME

Apache2::REST::Writer::xml - Apache2::REST::Response Writer for xml

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
    return 'text/xml' ;
}

=head2 asBytes

Returns the response as xml UTF8 bytes for output.

=cut

sub asBytes{
    my ($self,  $resp ) = @_ ;
    my $xmlString =  XMLout($resp , RootName => 'response' ) ;
    # xmlString is a string, not bytes
    # return bytes.
    return Encode::encode_utf8($xmlString) ;
}

1;
