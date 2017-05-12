package Apache2::REST::Writer::yaml_multipart;
use strict ;

use YAML;
use Data::Dumper ;

use base qw/Apache2::REST::WriterMultipart/;

our $PART_MIME_TYPE = 'text/yaml';

=head1 NAME

Apache2::REST::Writer::yaml_multipart - Apache2::REST::Response Writer for multipart yaml

=cut

=head2 new

=cut

sub new{
    my ( $class ) = @_;
    return bless {} , $class;
}

=head2 getNextPart

Returns the next chunk of data as yaml bytes along with a mime type

=cut

sub getNextPart {
    my ($self,  $resp) = @_;
    my $nextChunk = $resp->multipart_stream->nextChunk();
    unless( defined $nextChunk ){ return undef;}
    unless( ref $nextChunk ){
        confess($resp->stream()."->nextChunk MUST return a chunk of data as a reference, not a binary string");
    }
    # shallow unblessed copy
    my %resp = %$nextChunk;
    my $yaml = Dump(\%resp) ;
    ## yaml is a perl string, not bytes.
    my $data = Encode::encode_utf8($yaml) ;

    # Now, for multipart stuff we return a content type and data
    return {'mimetype' => $PART_MIME_TYPE, 'data' => $data};
}

1;
