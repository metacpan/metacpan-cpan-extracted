package Apache2::REST::Writer::xml_stream ;
use strict ;
use XML::Simple ;

use base qw/Apache2::REST::WriterStream/;

use Data::Dumper ;

=head1 NAME

Apache2::REST::Writer::xml_stream - Apache2::REST::Response Writer for streaming xml

=cut

=head1 METHODS

=head2 new

=cut

sub new{
    my ( $class ) = @_;
    return bless { xml_simple => XML::Simple->new() } , $class;
}

=head2 mimeType

Getter

=cut

sub mimeType{
    return 'application/xml' ; ## The framework requires this to be unique per writer type.
}

=head2 getPreambleBytes

Returns the response as xml UTF8 bytes for output.

=cut

sub getPreambleBytes{
    my ($self,  $resp ) = @_ ;
    ## To check: escape_value exists in XML::Simple object.
    my $xmlString = q|<?xml version="1.0" encoding="UTF-8" ?>
<response type="streamed" message="|.$self->{xml_simple}->escape_value($resp->message()).q|" status="|.$self->{xml_simple}->escape_value($resp->status()).q|">
|;
    
    $xmlString .=  XMLout($resp->data() , RootName => 'data' ) ;
    # xmlString is a string, not bytes
    # return bytes.
    return Encode::encode_utf8($xmlString) ;
}

sub getPostambleBytes{
    my ($self, $resp) = @_;
    ## Just close the response.
    return Encode::encode_utf8(q|
</response>
|);
}

sub getNextBytes{
    my ($self , $resp) = @_;
    my $nextChunk = $resp->stream->nextChunk();
    unless( defined $nextChunk ){ return undef;}
    unless( ref $nextChunk ){
	confess($resp->stream()."->nextChunk MUST return a chunk of data as a reference, not a binary string");
    }
    my $xmlString = XMLout($nextChunk , RootName => 'chunk' );
    return Encode::encode_utf8($xmlString);
}

1;
