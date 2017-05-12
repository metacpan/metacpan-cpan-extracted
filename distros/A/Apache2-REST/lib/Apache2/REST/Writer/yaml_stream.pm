package Apache2::REST::Writer::yaml_stream;
use strict ;

use YAML;
use Data::Dumper ;

use base qw/Apache2::REST::WriterStream/;

=head1 NAME

Apache2::REST::Writer::yaml_stream - Apache2::REST::Response Writer for streaming yaml

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
    return 'text/yaml';
}

=head2 getPreambleBytes

Returns the response preamble - nothing interesting here

=cut

sub getPreambleBytes{
    return Encode::encode_utf8("") ;
}


=head2 getPreambleBytes

Returns the response postamble - nothing interesting here

=cut
sub getPostambleBytes{
    my ($self, $resp) = @_;
    ## Just close the response.
    return Encode::encode_utf8("");
}

=head2 getNextBytes

Returns the next chunk of data as yaml bytes

=cut

sub getNextBytes {
    my ($self,  $resp) = @_;
    my $nextChunk = $resp->stream->nextChunk();
    unless( defined $nextChunk ){ return undef;}
    unless( ref $nextChunk ){
        confess($resp->stream()."->nextChunk MUST return a chunk of data as a reference, not a binary string");
    }
    # shallow unblessed copy
    my %resp = %$nextChunk;
    my $yaml = Dump(\%resp) ;
    ## yaml is a perl string, not bytes.
    return Encode::encode_utf8($yaml) ;
}

1;
